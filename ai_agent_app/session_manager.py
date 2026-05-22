# =====================================================================
# SessionManager: 사용자 세션 관리 (user_id 기반)
# =====================================================================
from typing import Dict, List, Optional


class SessionManager:
    """user_id 기반으로 사용자 세션 관리"""

    def __init__(self):
        self.sessions: Dict[str, Dict] = {}

    def create_or_get_session(self, user_id: str, user_query: Dict) -> str:
        """
        user_id로 세션 생성 또는 기존 세션 반환

        Args:
            user_id: 사용자 ID (백엔드에서 전달)
            user_query: 사용자 입력 정보

        Returns:
            user_id (세션 ID로 사용)
        """
        if user_id not in self.sessions:
            self.sessions[user_id] = {
                "user_query": user_query,
                "rejected_ids": [],
                "feedback_history": [],
                "last_graph_state": None,
            }
            print(f"[SessionManager] 새 세션 생성: {user_id}")
        else:
            print(f"[SessionManager] 기존 세션 재사용: {user_id}")
            # user_query 업데이트 (변경될 수 있음)
            self.sessions[user_id]["user_query"] = user_query

        print(f"[SessionManager] 현재 활성 세션 수: {len(self.sessions)}")
        return user_id

    def add_feedback(
        self, user_id: str, rejected_recipe_ids: List[str], reason: str
    ) -> None:
        """피드백 추가 (RCP_SEQ 리스트)"""
        print(f"[SessionManager] feedback 추가 시도: {user_id}")

        if user_id not in self.sessions:
            raise ValueError(f"사용자 세션을 찾을 수 없음: {user_id}")

        self.sessions[user_id]["rejected_ids"].extend(rejected_recipe_ids)
        self.sessions[user_id]["rejected_ids"] = list(
            set(self.sessions[user_id]["rejected_ids"])
        )
        self.sessions[user_id]["feedback_history"].append(
            {"rejected": rejected_recipe_ids, "reason": reason}
        )

    def get_rejected_ids(self, user_id: str) -> List[str]:
        """거절된 레시피 RCP_SEQ 조회"""
        if user_id not in self.sessions:
            return []
        return self.sessions[user_id]["rejected_ids"]

    def get_user_query(self, user_id: str) -> Dict:
        """사용자 입력 정보 조회"""
        if user_id not in self.sessions:
            return {}
        return self.sessions[user_id]["user_query"]

    def save_graph_state(self, user_id: str, state: Dict) -> None:
        """그래프 실행 상태 저장"""
        if user_id in self.sessions:
            self.sessions[user_id]["last_graph_state"] = state

    def get_last_graph_state(self, user_id: str) -> Optional[Dict]:
        """저장된 그래프 상태 조회"""
        if user_id not in self.sessions:
            return None
        return self.sessions[user_id]["last_graph_state"]

