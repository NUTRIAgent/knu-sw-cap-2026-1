from typing import Any, Dict, List

from langchain_openai import ChatOpenAI
from langchain_core.output_parsers import JsonOutputParser
from langchain_core.prompts import ChatPromptTemplate

class SelectCandidates:
    def __init__(self, model: ChatOpenAI):
        self.model = model
        self.parser = JsonOutputParser()

    def _build_context(self, recipes: List[Dict]) -> str:
        return "\n".join([
            f"ID:{i}|메뉴:{r['RCP_NM']}|열량:{r['INFO_ENG']}kcal|"
            f"단백질:{r['INFO_PRO']}g|탄수화물:{r['INFO_CAR']}g|지방:{r['INFO_FAT']}g|"
            f"나트륨:{r['INFO_NA']}mg|재료:{r['RCP_PARTS_DTLS']}"
            for i, r in enumerate(recipes[:100])
        ])

    def select_candidates(self, recipes: List[Dict], query: Dict) -> List[int]:
        context = self._build_context(recipes)

        prompt = ChatPromptTemplate.from_messages([
            (
                "system",
                "당신은 전문 영양사입니다. 사용자의 프로필을 분석하여 최적의 식단 ID를 선정하세요. "
                "반드시 JSON으로만 답하세요. 형식: {{\"candidate_ids\": [0, 1, 2]}} (최대 10개)"
            ),
            ("human", (
                "[사용자 정보]\n"
                "신체 정보: {height}cm, {weight}kg\n"
                "건강 상태: {health}\n"
                "알러지: {allergy}\n"
                "선호: {preferences}\n"
                "운동 목표: {goal}\n\n"
                "[레시피 목록]\n{context}"
            ))
        ])

        chain = prompt | self.model | self.parser
        try:
            response = chain.invoke({
                "height": query.get('height_cm'),
                "weight": query.get('weight_kg'),
                "health": ", ".join(query.get('health_conditions', [])) or "없음",
                "allergy": ", ".join(query.get('allergies', [])) or "없음",
                "preferences": query.get('preferences', "없음"),
                "goal": query.get('fitness_goal'),
                "context": context
            })
            if not isinstance(response, dict):
                return []
            candidate_ids: Any = response.get('candidate_ids', [])
            if not isinstance(candidate_ids, list):
                return []

            out: List[int] = []
            for x in candidate_ids:
                try:
                    out.append(int(x))
                except Exception:
                    continue
            print(out)  # 모델이 어떤 응답을 주는지 확인용
            return out[:10]
        except Exception as e:
            print(f"Error in select_candidates: {e}")
            return []