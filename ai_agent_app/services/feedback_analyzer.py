# =====================================================================
# FeedbackAnalyzer: 사용자 피드백 이유 분석
# =====================================================================
from langchain_openai import ChatOpenAI


class FeedbackAnalyzer:
    """사용자 피드백 이유를 LLM으로 분석해서 제약 조건으로 변환"""

    def __init__(self, model: ChatOpenAI):
        self.model = model

    async def analyze(self, feedback_reason: str) -> str:
        """
        피드백 이유를 분석해서 다음 rank_node에 반영할 제약 생성

        예시:
        - "너무 매움" → "매운맛을 피하고 순한 음식"
        - "가격이 비쌈" → "저가격 메뉴 우선"
        - "너무 무거움" → "가볍고 소화하기 좋은 음식"

        Args:
            feedback_reason: 사용자가 제시한 거절 이유

        Returns:
            다음 추천에 반영할 제약 조건
        """
        prompt = f"""사용자가 다음 이유로 메뉴를 거절했습니다: "{feedback_reason}"

이 거절 이유를 분석해서 다음 추천에 반영할 요구사항을 한 문장으로 정리해주세요.
예시:
- "너무 매움" → "매운맛을 피하고 순한 음식"
- "가격이 비쌈" → "저가격 메뉴 우선"
- "너무 무거움" → "가볍고 소화하기 좋은 음식"

답변은 "~를 피하고" 또는 "~를 우선" 형태로 간결하게:"""

        response = await self.model.ainvoke(prompt)
        constraint = response.content.strip()
        print(f"[FeedbackAnalyzer] '{feedback_reason}' → '{constraint}'")
        return constraint
