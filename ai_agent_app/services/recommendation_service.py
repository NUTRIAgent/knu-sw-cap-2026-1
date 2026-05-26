# =====================================================================
# RecommendationService: 추천 전체 흐름 조율
# =====================================================================
from typing import Dict, List, Any, Optional
from ai_agent_app.services.recommendation_engine import RecommendationEngine


class RecommendationService:
    """추천 엔진을 조율하는 서비스"""

    def __init__(
        self,
        recommendation_engine: RecommendationEngine,
        session_manager: "SessionManager",
        recipes: List[Dict] = None,
    ):
        self.engine = recommendation_engine
        self.session_manager = session_manager
        self.recipes = recipes or []

    async def recommend(self, user_id: str, user_query: Dict, recipes: Optional[List[Dict]] = None, history_texts: Optional[List[str]] = None) -> Dict[str, Any]:
        """
        초기 추천 실행

        Args:
            user_id: 사용자 ID (백엔드에서 전달)
            user_query: 사용자 입력 정보
            recipes: 런타임 레시피 목록 (None이면 self.recipes 사용)

        Returns:
            {
                "user_id": str,
                "recommendations": List[Dict]
            }
        """
        print(f"[RecommendationService] 사용자 {user_id}의 초기 추천 시작")

        active_recipes = recipes if recipes is not None else self.recipes

        # user_id 기반 세션 생성 또는 조회
        self.session_manager.create_or_get_session(user_id, user_query)

        # 그래프 실행
        final_state = await self.engine.get_initial_recommendations(
            active_recipes, user_query, history_texts or []
        )

        if final_state.get("error"):
            raise ValueError(final_state["error"])

        results = final_state.get("final_results", [])

        # 상태 저장
        self.session_manager.save_graph_state(user_id, final_state)

        return {"user_id": user_id, "recommendations": results}
