# =====================================================================
# RecommendationEngine: LangGraph 기반 추천 엔진
# =====================================================================
from typing import Dict, List, Any, Optional
from ai_agent_app.RecipeGraph import RecipeGraphBuilder


def _build_recipes_by_seq(recipes: List[Dict]) -> Dict[str, Dict]:
    """recipes 리스트에서 식별자 -> recipe dict 매핑 생성.
    Spring 데이터는 MENU_ID, 로컬 JSON 폴백은 RCP_SEQ 를 사용.
    """
    def _id(r):
        return str(r.get("MENU_ID") or r.get("RCP_SEQ", "")).strip()
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
            "rejected_ids": [],
            "feedback_reason": None,
            "feedback_constraints": None,
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

    async def get_feedback_recommendations(
        self,
        recipes: List[Dict],
        user_query: Dict,
        rejected_ids: List[str],
        feedback_reason: str,
        feedback_constraints: str,
        prev_state: Dict,
    ) -> Dict[str, Any]:
        """피드백 기반 재추천"""
        print("[RecommendationEngine] 피드백 기반 추천 시작")

        rejected_set = set(rejected_ids)
        top10 = prev_state.get("top10_ids", [])
        remaining = [s for s in top10 if s not in rejected_set]

        if len(remaining) >= 5:
            print(f"[RecommendationEngine] 빠른 경로: top10 잔여 {len(remaining)}개")
            fast_state = {
                **prev_state,
                "rejected_ids": rejected_ids,
                "feedback_reason": feedback_reason,
                "feedback_constraints": feedback_constraints,
                "user_query": user_query,
                "recipes": recipes,
                "recipes_by_seq": prev_state.get("recipes_by_seq") or _build_recipes_by_seq(recipes),
            }
            final_state = await self.graph_builder.analyze_with_rejection(fast_state)
        else:
            print(f"[RecommendationEngine] top10 소진(잔여 {len(remaining)}개) → 전체 재실행")
            state = {
                "recipes": recipes,
                "recipes_by_seq": _build_recipes_by_seq(recipes),
                "user_query": user_query,
                "rejected_ids": rejected_ids,
                "feedback_reason": feedback_reason,
                "feedback_constraints": feedback_constraints,
                "filtered_recipes": [],
                "allowed_ids": [],
                "history_texts": prev_state.get("history_texts", []),
                "candidate_ids": [],
                "enriched": [],
                "price_cache": {},
                "top5_ids": [],
                "top10_ids": [],
                "final_results": [],
                "error": None,
            }
            final_state = await self.graph.ainvoke(state)
        return final_state
