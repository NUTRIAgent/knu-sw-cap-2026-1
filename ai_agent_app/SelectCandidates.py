from typing import Any, Dict, List, Optional

from langchain_openai import ChatOpenAI
from langchain_core.output_parsers import JsonOutputParser
from langchain_core.prompts import ChatPromptTemplate

from ai_agent_app.GoalGuidelines import format_guideline


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

    @staticmethod
    def _format_history(history_texts: Optional[List[str]]) -> str:
        if not history_texts:
            return "(이력 없음)"
        return "\n".join(f"- {t}" for t in history_texts)

    def select_candidates(
        self,
        recipes: List[Dict],
        query: Dict,
        history_texts: Optional[List[str]] = None,
    ) -> List[int]:
        context = self._build_context(recipes)
        history_block = self._format_history(history_texts)

        prompt = ChatPromptTemplate.from_messages([
            (
                "system",
                "당신은 전문 영양사입니다. 사용자의 프로필과 과거 식사 이력을 종합 분석하여 "
                "가장 적합한 식단 ID를 선정하세요. 별점 낮은 이력은 사용자가 싫어한 패턴을 "
                "암시하므로 피해야 합니다. "
                "정확히 10개를 선정하세요. (후보가 10개 미만이면 가능한 만큼 모두 선정) "
                "반드시 JSON으로만 답하세요. 형식: {{\"candidate_ids\": [0, 1, 2, ...]}}"
            ),
            ("human", (
                "[사용자 정보]\n"
                "신체 정보: {height}cm, {weight}kg\n"
                "건강 상태: {health}\n"
                "알러지: {allergy}\n"
                "선호: {preferences}\n"
                "운동 목표: {goal}\n\n"
                "{guideline}\n\n"
                "[과거 식사 이력 (현재 요청과 관련 있는 항목)]\n"
                "{history}\n\n"
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
                "preferences": ", ".join(query.get('preferences', [])) or "없음",
                "goal": query.get('fitness_goal'),
                "guideline": format_guideline(query.get('fitness_goal', '일반식단')),
                "history": history_block,
                "context": context,
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
            print(f"[SelectCandidates] LLM 응답 IDs: {out}")
            return out[:10]
        except Exception as e:
            print(f"Error in select_candidates: {e}")
            return []
