# =====================================================================
# RecommendationEngine: LangGraph 기반 추천 엔진
# =====================================================================
from typing import Dict, List, Any, Optional
from ai_agent_app.RecipeGraph import RecipeGraphBuilder


def _build_recipes_by_seq(recipes: List[Dict]) -> Dict[str, Dict]:
    """recipes 리스트에서 MENU_ID -> recipe dict 매핑 생성."""
    def _id(r):
        return str(r.get("MENU_ID", "")).strip()
    return {_id(r): r for r in recipes if _id(r)}


class RecommendationEngine:
    """LangGraph를 통한 레시피 추천 실행"""

    def __init__(self, graph_builder: RecipeGraphBuilder):
        self.graph_builder = graph_builder
        self.graph = graph_builder.build()

    async def get_initial_recommendations(
        self,
        recipes: List[Dict],
        user_query: Dict,
        history_texts: Optional[List[str]] = None,
    ) -> Dict[str, Any]:
        """초기 추천 (전체 파이프라인 실행)"""
        print("[RecommendationEngine] 초기 추천 시작")

        if history_texts is None:
            history_texts = []

        initial_state = {
            "recipes": recipes,
            "recipes_by_seq": _build_recipes_by_seq(recipes),
            "user_query": user_query,
            "filtered_recipes": [],
            "allowed_ids": [],
            "history_texts": history_texts,
            "candidate_ids": [],
            "enriched": [],
            "price_cache": {},
            "top5_ids": [],
            "top10_ids": [],
            "final_results": [],
            "error": None,
        }

        final_state = await self.graph.ainvoke(initial_state)
        return final_state

    async def stream_initial_recommendations(
        self,
        recipes: List[Dict],
        user_query: Dict,
        history_texts: Optional[List[str]] = None,
    ):
        """초기 추천 파이프라인을 실행하고 analyze 결과를 완료 순서대로 yield (SSE용)"""
        print("[RecommendationEngine] SSE 스트리밍 추천 시작")

        if history_texts is None:
            history_texts = []

        state = {
            "recipes": recipes,
            "recipes_by_seq": _build_recipes_by_seq(recipes),
            "user_query": user_query,
            "filtered_recipes": [],
            "allowed_ids": [],
            "history_texts": history_texts,
            "candidate_ids": [],
            "enriched": [],
            "price_cache": {},
            "top5_ids": [],
            "top10_ids": [],
            "final_results": [],
            "error": None,
        }

        state = await self.graph_builder.candidate_node(state)
        if state.get("error"):
            raise ValueError(state["error"])

        state = await self.graph_builder.price_node(state)
        if state.get("error"):
            raise ValueError(state.get("error", "price_node 오류"))

        state = await self.graph_builder.rank_node(state)
        if state.get("error"):
            raise ValueError(state["error"])

        async for result in self.graph_builder.stream_analyze(state):
            yield result

    async def analyze_single(
        self,
        recipe: Dict,
        user_query: Dict,
    ) -> Dict[str, Any]:
        """사용자가 직접 고른 메뉴 1개만 가격 조회 + 상세 분석 (candidate/rank 생략).

        Args:
            recipe: 선택된 메뉴 1개의 레시피 dict (Spring 포맷, MENU_ID 포함)
            user_query: 사용자 입력 정보

        Returns:
            analyze 결과 dict (초기 추천 아이템과 동일한 형식)
        """
        print("[RecommendationEngine] 단일 메뉴 분석 시작")

        seq = str(recipe.get("MENU_ID", "")).strip()
        if not seq:
            raise ValueError("선택한 메뉴의 MENU_ID가 없습니다.")

        # 가격은 recipe에 백엔드 선계산 값(INGREDIENT_COSTS/TOTAL_COST)이 이미 포함됨 (#155)
        state = {
            "recipes_by_seq": {seq: recipe},
            "user_query": user_query,
        }
        return await self.graph_builder._analyze_one(seq, state)
