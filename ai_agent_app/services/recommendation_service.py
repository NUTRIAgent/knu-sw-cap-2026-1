# =====================================================================
# RecommendationService: 추천 전체 흐름 조율
# =====================================================================
from typing import Dict, List, Any, Optional
from services.recommendation_engine import RecommendationEngine
from services.feedback_analyzer import FeedbackAnalyzer


class RecommendationService:
    """추천 엔진과 피드백 분석을 조율하는 서비스"""

    def __init__(
        self,
        recommendation_engine: RecommendationEngine,
        feedback_analyzer: FeedbackAnalyzer,
        session_manager: "SessionManager",
        recipes: List[Dict],
    ):
        self.engine = recommendation_engine
        self.analyzer = feedback_analyzer
        self.session_manager = session_manager
        self.recipes = recipes

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

        # 상태 저장 (다음 피드백용)
        self.session_manager.save_graph_state(user_id, final_state)

        return {"user_id": user_id, "recommendations": results}

    async def provide_feedback(
        self, user_id: str, rejected_recipe_ids: List[str], reason: str
    ) -> Dict[str, Any]:
        """피드백 처리 및 재추천 (RCP_SEQ 기준)"""
        print(f"[RecommendationService] 사용자 {user_id}의 피드백 처리 시작")

        # 피드백 저장 (RCP_SEQ 문자열로 받음)
        self.session_manager.add_feedback(user_id, [str(s) for s in rejected_recipe_ids], reason)

        # 이전 상태 조회
        prev_state = self.session_manager.get_last_graph_state(user_id)
        if not prev_state or "enriched" not in prev_state:
            raise ValueError("이전 추천 상태를 찾을 수 없습니다")

        # 피드백 이유 분석
        feedback_constraints = await self.analyzer.analyze(reason)

        # 사용자 정보 조회
        user_query = self.session_manager.get_user_query(user_id)
        rejected_ids = self.session_manager.get_rejected_ids(user_id)

        print(f"[RecommendationService] 누적 거절: {rejected_ids}")
        print(f"[RecommendationService] 제약: {feedback_constraints}")

        # 재추천 실행 (초기 추천 때 사용한 recipes 재사용)
        final_state = await self.engine.get_feedback_recommendations(
            prev_state.get("recipes", self.recipes),
            user_query,
            rejected_ids,
            reason,
            feedback_constraints,
            prev_state,
        )

        if final_state.get("error"):
            raise ValueError(final_state["error"])

        results = final_state.get("final_results", [])

        # 상태 저장 (연쇄 피드백 대비)
        self.session_manager.save_graph_state(user_id, final_state)

        feedback_count = len(
            self.session_manager.sessions[user_id]["feedback_history"]
        )

        return {
            "user_id": user_id,
            "feedback_count": feedback_count,
            "applied_constraint": feedback_constraints,
            "recommendations": results,
        }
