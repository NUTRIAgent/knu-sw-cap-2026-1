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
        context: Optional[Dict] = None,
    ):
        text = self._format_text(recipe_name, comment, rating, context)
        doc = Document(
            page_content=text,
            metadata={
                "user_id": user_id,
                "recipe_id": str(recipe_id),
                "rating": float(rating),
            },
        )
        self.vectorstore.add_documents([doc])

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
        return [doc.page_content for doc, _ in results]
