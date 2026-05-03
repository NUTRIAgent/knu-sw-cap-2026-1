import re
from typing import List, Dict
from pydantic import BaseModel, Field
from langchain_openai import ChatOpenAI
from langchain.schema import SystemMessage, HumanMessage
from langchain.output_parsers import ResponseSchema, StructuredOutputParser
from langchain.prompts import ChatPromptTemplate

class selectCandidates:
    def __init__(self, model: ChatOpenAI):
        response_schemas = [
            ResponseSchema(name="candidate_ids", description="선택된 레시피의 ID 리스트 (최대 10개)", type="list[int]")
        ]
        self.parser = StructuredOutputParser.from_response_schemas(response_schemas)
        self.model = model
    
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
            ("system", "당신은 전문 영양사입니다. 사용자의 프로필을 분석하여 최적의 식단 ID를 선정하세요.\n{format_instructions}"),
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
                "format_instructions": self.parser.get_format_instructions(),
                "height": query.get('height_cm'),
                "weight": query.get('weight_kg'),
                "health": ", ".join(query.get('health_conditions', [])) or "없음",
                "allergy": ", ".join(query.get('allergies', [])) or "없음",
                "preferences": query.get('preferences', "없음"),
                "goal": query.get('fitness_goal'),
                "context": context
            })
            print(response.get('candidate_ids', [])) # 모델이 어떤 응답을 주는지 확인용
            return response.get('candidate_ids', [])[:10]
            
        except Exception as e:
            print(f"Error in select_candidates: {e}")
            return []