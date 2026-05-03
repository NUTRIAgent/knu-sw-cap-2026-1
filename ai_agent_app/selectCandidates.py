import re
from typing import List, Dict

from langchain_openai import ChatOpenAI
from langchain.schema import SystemMessage, HumanMessage

class selectCandidates:
    def __init__(self, recipes: List[Dict], model: ChatOpenAI):
        self.recipes = recipes
        self.model = model
    def select_candidates(self, query: Dict) -> List[int]:
        context = "\n".join([
            (
                f"ID:{i}|메뉴:{r['RCP_NM']}|열량:{r['INFO_ENG']}kcal|"
                f"단백질:{r['INFO_PRO']}g|탄수화물:{r['INFO_CAR']}g|지방:{r['INFO_FAT']}g|"
                f"나트륨:{r['INFO_NA']}mg|재료:{r['RCP_PARTS_DTLS']}"
            )
            for i, r in enumerate(self.recipes[:100])
        ])

        health_str = ", ".join(query.get('health_conditions', [])) if query.get('health_conditions') else "없음"
        allergy_str = ", ".join(query.get('allergies', [])) if query.get('allergies') else "없음"

        system_prompt = (
                    "당신은 영양사입니다. 사용자의 신체 정보와 건강 상태를 분석하여 "
                    "제공된 레시피 목록 중 가장 적합한 10개의 ID를 선택하세요. "
                    "응답은 반드시 다른 설명 없이 숫자와 콤마(,)로만 구성해야 합니다. 예: 1, 2, 3"
                    )
        prompt = f"""
                    [사용자 정보]
                    신체 정보: 키 {query.get('height_cm')}cm, 체중 {query.get('weight_kg')}kg
                    건강 상태: {health_str}
                    알러지: {allergy_str}
                    선호: {query.get('preferences')}
                    운동 목표: {query.get('fitness_goal')}
                    "[레시피 목록]\n{context}"
                """
            
        try:
            messages = [
                SystemMessage(content=system_prompt),
                HumanMessage(content=prompt)
            ]
            res = self.model.invoke(messages).content

            candidate_ids = [int(i) for i in re.findall(r'\d+', res)]
            print(candidate_ids[:10])  # 모델이 어떤 응답을 주는지 확인용
            return candidate_ids[:10]
        except Exception as e:
            print(f"Error in select_candidates: {e}")
            return []