# =====================================================================
# RecipeGraph.py - MENU_ID 기반 식별자로 통일된 LangGraph 워크플로우
# =====================================================================

from typing import List, Dict, Any, TypedDict, Optional
from langgraph.graph import StateGraph, END
from langchain_openai import ChatOpenAI
from langchain_core.output_parsers import JsonOutputParser
import re
import asyncio
from ai_agent_app.GetMarketPrices import GetMarketPrices
from ai_agent_app.SelectCandidates import SelectCandidates
from ai_agent_app.Prompts import get_recipe_prompt
from ai_agent_app import ProcessDynamicInputs
from ai_agent_app.GoalGuidelines import format_guideline


# =====================================================================
# GraphState: 노드 간 공유 상태
# - 모든 ID는 MENU_ID 문자열 (Spring 메뉴 PK)
# - recipes_by_seq: MENU_ID -> recipe 빠른 룩업 dict
# =====================================================================
class GraphState(TypedDict):
    # 입력
    recipes: List[Dict]
    recipes_by_seq: Dict[str, Dict]
    user_query: Dict
    history_texts: List[str]  # 벡터 검색으로 추출한 관련 이력 텍스트 (LLM 컨텍스트용)

    # [candidate_node] 출력
    filtered_recipes: List[Dict]
    allowed_ids: List[str]
    candidate_ids: List[str]

    # [price_node] 출력
    enriched: List[str]
    price_cache: Dict[str, str]

    # [rank_node] 출력
    top5_ids: List[str]
    top10_ids: List[str]

    # 최종
    final_results: List[Dict[str, Any]]
    error: Optional[str]


class RecipeGraphBuilder:
    def __init__(
        self,
        get_market_prices: GetMarketPrices,
        select_candidates: SelectCandidates,
        model: ChatOpenAI,
        recipes: List[Dict] = None,
    ):
        self.recipes = recipes or []
        self.get_market_prices = get_market_prices
        self.select_candidates = select_candidates
        self.model = model
        self.chain = get_recipe_prompt() | self.model | JsonOutputParser()

    # ------------------------------------------------------------------
    # candidate_node: 전체 후보(이미 Spring이 알러지 필터링함)에서 LLM이 10개 선정
    # ------------------------------------------------------------------
    def candidate_node(self, state: GraphState) -> GraphState:
        print("[candidate_node] 후보 추출 시작")

        # 식별자/목록 생성 (알러지·거절은 Spring 백엔드가 이미 처리)
        allowed_ids: List[str] = []
        filtered_recipes: List[Dict] = []
        for r in state["recipes"]:
            seq = str(r.get("MENU_ID", "")).strip()
            if not seq:
                continue
            allowed_ids.append(seq)
            filtered_recipes.append(r)

        if not allowed_ids:
            return {**state, "error": "후보 레시피가 없습니다."}

        history_texts = state.get("history_texts", [])
        print(f"[candidate_node] 후보 {len(allowed_ids)}개 / 관련 이력 {len(history_texts)}개 컨텍스트로 사용")

        try:
            llm_local_ids = self.select_candidates.select_candidates(
                filtered_recipes,
                state["user_query"],
                history_texts=history_texts,
            )
            candidate_ids = [allowed_ids[i] for i in llm_local_ids if 0 <= i < len(allowed_ids)]
        except Exception as e:
            return {**state, "error": str(e)}

        if not candidate_ids:
            return {**state, "error": "적합한 레시피 후보가 없습니다."}
        return {
            **state,
            "filtered_recipes": filtered_recipes,
            "allowed_ids": allowed_ids,
            "candidate_ids": candidate_ids[:10],
        }

    # ------------------------------------------------------------------
    # price_node: MENU_ID로 룩업 + 가격 조회 (병렬)
    # ------------------------------------------------------------------
    async def price_node(self, state: GraphState) -> GraphState:
        print("[price_node] 후보 가격 조회 (병렬)")
        location = state["user_query"].get("location")
        recipes_by_seq = state["recipes_by_seq"]

        async def fetch_one(seq: str):
            r = recipes_by_seq[seq]
            try:
                p_info = await asyncio.to_thread(
                    self.get_market_prices.get_market_prices,
                    r["RCP_PARTS_DTLS"],
                    location,
                )
                rough_cost = self.get_market_prices.estimate_serving_cost(
                    r["RCP_PARTS_DTLS"], p_info
                )
            except Exception:
                p_info = "가격 데이터 조회 실패"
                rough_cost = 0
            return seq, r, p_info, rough_cost

        results = await asyncio.gather(*[fetch_one(seq) for seq in state["candidate_ids"]])

        price_cache = {seq: p_info for seq, _, p_info, _ in results}
        enriched = [
            ProcessDynamicInputs.format_enriched(seq, r, p_info, rough)
            for seq, r, p_info, rough in results
        ]
        return {**state, "enriched": enriched, "price_cache": price_cache}

    # ------------------------------------------------------------------
    # rank_node
    # ------------------------------------------------------------------
    def rank_node(self, state: GraphState) -> GraphState:
        print("[rank_node] LLM으로 상위 10개 랭킹 선정")
        enriched = state["enriched"]
        candidate_ids = state["candidate_ids"]

        uq = state["user_query"]
        goal = uq.get('fitness_goal', '일반식단')
        prompt = (
            "[사용자 정보]\n"
            f"예산: {uq.get('budget')}원\n"
            f"목표: {goal}\n"
            f"건강 상태: {', '.join(uq.get('health_conditions', [])) or '없음'}\n"
            f"선호: {', '.join(uq.get('preferences', [])) or '없음'}\n\n"
            f"현재 날씨: {uq.get('weather_temp')}°C {uq.get('weather_condition', '')}\n"
            f"{format_guideline(goal)}\n\n"
            "[종합 판단 지침]\n"
            "- 더운 날(28°C↑)은 시원한 메뉴, 추운 날/비/눈은 따뜻한 국물 메뉴 등 날씨에 따라 어울리는 메뉴의 경우 가산점을 부여할 것.\n"
            "- '추정조리비'는 일부 재료만 매칭된 부정확한 값일 수 있음. 절대적 기준이 아님.\n"
            "- 예산을 크게 초과하는지 참고만 하고, 영양/취향/건강 적합성을 우선 고려.\n"
            "- '추정불가'로 표시된 항목도 정상이므로 다른 기준으로 평가할 것.\n"
            "- 선호와 건강 상태에 더 잘 맞는 메뉴가 추정조리비 약간 높아도 우선될 수 있음.\n\n"
            "아래 후보 중 사용자에게 가장 적합한 10개를 순서대로 선정.\n"
            "반드시 마지막 줄에 다음 형식으로만 답하세요 (다른 설명 금지):\n"
            "랭킹ID: <ID1>, <ID2>, <ID3>, <ID4>, <ID5>, <ID6>, <ID7>, <ID8>, <ID9>, <ID10>\n"
            "----------------------\n"
            + "\n".join(enriched)
        )

        try:
            raw = self.model.invoke(prompt).content
            match = re.search(r"랭킹ID:\s*([\w,\s]+)", raw)
            if not match:
                raise ValueError(f"LLM 응답에서 '랭킹ID:' 앵커를 찾을 수 없습니다. 응답: {raw!r}")

            parsed = [x.strip() for x in match.group(1).split(",") if x.strip()]
            candidate_set = set(candidate_ids)
            top10_ids = [s for s in parsed if s in candidate_set][:10]

            if not top10_ids:
                raise ValueError("유효한 랭킹 ID가 없습니다.")

            top5_ids = top10_ids[:5]
            return {**state, "top5_ids": top5_ids, "top10_ids": top10_ids}
        except Exception as e:
            return {**state, "error": str(e)}

    # ------------------------------------------------------------------
    # analyze_node
    # ------------------------------------------------------------------
    async def _analyze_one(self, seq: str, state: GraphState):
        recipe = state["recipes_by_seq"][seq]
        price_info = state["price_cache"].get(seq, "가격 데이터 없음")

        static_data = ProcessDynamicInputs.build_static_data(recipe)

        try:
            llm_input = ProcessDynamicInputs.build_llm_input(recipe, price_info, state["user_query"])
            llm_data = await self.chain.ainvoke(llm_input)
        except Exception as e:
            llm_data = {"error": str(e)}

        result = {**static_data, **llm_data}

        if "market_prices" in result and isinstance(result["market_prices"], list):
            result["total_estimated_cost"] = sum(
                float(p.get("calculated_cost", 0))
                for p in result["market_prices"]
            )
        return result

    async def stream_analyze(self, state: GraphState):
        """Top5 분석 결과를 완료된 순서대로 yield (SSE용)"""
        tasks = [self._analyze_one(seq, state) for seq in state["top5_ids"]]
        for coro in asyncio.as_completed(tasks):
            result = await coro
            yield result

    async def analyze_node(self, state: GraphState) -> GraphState:
        print("[analyze_node] 상위 5개 상세 분석 (병렬 처리)")
        tasks = [self._analyze_one(seq, state) for seq in state["top5_ids"]]
        final_results = await asyncio.gather(*tasks)
        return {**state, "final_results": final_results}

    def build(self):
        graph = StateGraph(GraphState)

        graph.add_node("candidate_node", self.candidate_node)
        graph.add_node("price_node", self.price_node)
        graph.add_node("rank_node", self.rank_node)
        graph.add_node("analyze_node", self.analyze_node)

        graph.set_entry_point("candidate_node")
        graph.add_conditional_edges(
            "candidate_node",
            lambda s: END if s.get("error") else "price_node",
        )
        graph.add_conditional_edges(
            "rank_node",
            lambda s: END if s.get("error") else "analyze_node",
        )
        graph.add_edge("price_node", "rank_node")
        graph.add_edge("analyze_node", END)

        return graph.compile()
