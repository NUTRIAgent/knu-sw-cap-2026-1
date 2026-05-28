from typing import Optional
from langchain_openai import ChatOpenAI


class WeatherAdvisor:
    """날씨 정보를 받아 한 줄 건강/식사 브리핑 멘트를 생성한다."""

    def __init__(self, model: ChatOpenAI):
        self.model = model

    async def generate(
        self,
        temperature: float,
        condition: str = "",
        humidity: Optional[float] = None,
        location_name: Optional[str] = None,
    ) -> str:
        loc = f"{location_name} " if location_name else ""
        hum = f", 습도 {humidity}%" if humidity is not None else ""
        prompt = (
            f"현재 {loc}날씨: 기온 {temperature}°C, {condition}{hum}\n\n"
            "이 날씨에 맞는 식사·건강 브리핑을 딱 한 문장(존댓말, 40자 이내)으로 작성하세요. "
            "이모지나 따옴표 없이 문장만 출력하세요.\n"
            "예시: 오늘 기온이 30도를 넘었어요. 수분 보충에 신경 써주세요."
        )
        res = await self.model.ainvoke(prompt)
        return res.content.strip()