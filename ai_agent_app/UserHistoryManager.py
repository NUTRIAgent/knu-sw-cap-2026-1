from typing import List, Dict, Optional
from langchain_chroma import Chroma
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_core.documents import Document


class UserHistoryManager:
    """유저 식사 이력 저장소
    - 저장: 메뉴 + 코멘트 + 별점 + 당시 user_query 컨텍스트
    - 조회: 현재 요청과 의미적으로 가까운 과거 이력 K개 (벡터 검색)
    """

    def __init__(self, persist_dir: str = "./user_history_db"):
        self.embeddings = HuggingFaceEmbeddings(model_name="BAAI/bge-m3")
        self.vectorstore = Chroma(
            persist_directory=persist_dir,
            embedding_function=self.embeddings,
        )

    def save(
        self,
        user_id: str,
        recipe_id: str,
        recipe_name: str,
        comment: str,
        rating: float,
        log_id: int,
        context: Optional[Dict] = None,
    ):
        # 같은 log_id 재저장(피드백 수정) 시 중복 방지: 먼저 제거 후 추가 (멱등)
        self.delete(log_id)
        text = self._format_text(recipe_name, comment, rating, context)
        doc = Document(
            page_content=text,
            metadata={
                "user_id": user_id,
                "recipe_id": str(recipe_id),
                "rating": float(rating),
                "log_id": int(log_id),  # recommendation_logs PK (정확 삭제 키)
            },
        )
        self.vectorstore.add_documents([doc])

    def delete(self, log_id: int):
        """피드백 삭제 시 해당 RAG 문서 제거 (log_id 정확 매칭)."""
        try:
            self.vectorstore._collection.delete(where={"log_id": int(log_id)})
        except Exception as e:
            print(f"[UserHistoryManager] 삭제 실패 log_id={log_id}: {e}")

    @staticmethod
    def _format_text(
        recipe_name: str,
        comment: str,
        rating: float,
        context: Optional[Dict] = None,
    ) -> str:
        parts = [
            f"메뉴: {recipe_name}",
            f"코멘트: {comment}",
            f"별점: {rating}",
        ]
        if context:
            goal = context.get("fitness_goal")
            healths = context.get("health_conditions") or []
            prefs = context.get("preferences") or []
            if goal:
                parts.append(f"목표: {goal}")
            if healths:
                parts.append(f"건강: {', '.join(healths)}")
            if prefs:
                parts.append(f"선호: {', '.join(prefs)}")
        return ", ".join(parts)

    @staticmethod
    def build_query(user_query: Dict) -> str:
        goal = user_query.get("fitness_goal", "")
        healths = user_query.get("health_conditions") or []
        prefs = user_query.get("preferences") or []
        parts = []
        if goal:
            parts.append(f"목표: {goal}")
        if healths:
            parts.append(f"건강: {', '.join(healths)}")
        if prefs:
            parts.append(f"선호: {', '.join(prefs)}")
        return ", ".join(parts) or "일반 식단"

    async def search_relevant_history(
        self,
        user_id: str,
        user_query: Dict,
        k: int = 5,
    ) -> List[str]:
        if not user_id:
            return []
        query = self.build_query(user_query)
        try:
            results = await self.vectorstore.asimilarity_search_with_score(
                query=query,
                k=k,
                filter={"user_id": user_id},
            )
        except Exception as e:
            print(f"[UserHistoryManager] 검색 실패: {e}")
            return []

        # [DEBUG] 벡터DB에서 가져온 값 확인
        print(f"[RAG][DEBUG] user_id={user_id} | query='{query}' | 검색결과 {len(results)}건")
        for doc, score in results:
            print(f"[RAG][DEBUG]   score={score:.4f} | meta={doc.metadata} | text='{doc.page_content}'")

        return [doc.page_content for doc, _ in results]
