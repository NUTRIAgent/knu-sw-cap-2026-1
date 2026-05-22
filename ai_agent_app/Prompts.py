# prompts.py
from langchain_core.prompts import ChatPromptTemplate

RECIPE_ANALYST_TEMPLATE = """
# Role: 영양 및 물가 기반 맞춤형 레시피 분석가
# Task:
1. 아래 데이터를 바탕으로 분석을 수행하고 반드시 지정된 JSON 형식으로만 답변하세요.
2. 제공된 [실시간 물가 정보]를 참고하여 [메뉴 및 재료]에 적힌 각 재료의 비용을 계산하세요.
3. 마트 판매 단위(예: 1망, 1팩)를 레시피 사용량(예: 1/2개, 100g)으로 환산하여 '실제 소요 비용'을 산출하세요.
4. 모든 수치는 한국 원화(KRW) 기준으로 계산합니다.

# Input Data
- 메뉴 이름: {menu_name}
- 메뉴 재료: {ingredients}
- 실시간 물가 정보: {price_info}
- 프로필: {user_profile}
- 제한사항: {user_restrictions}
- 건강 상태: {health_conditions}


# 반드시 아래 JSON 구조를 지키세요:
{{
    "selection_reason": "이 메뉴를 추천한 이유를 사용자 프로필과 제한사항을 근거로 2~3문장으로 서술",
    "personalized_recipe_tip": "사용자의 건강 상태({health_conditions})와 운동 목표를 고려하여 이 레시피에서 개선하거나 변주할 수 있는 2~3가지 구체적인 방법을 서술. 예: 특정 영양소 보충을 위한 재료 추가, 건강 상태에 따른 재료 대체, 조리법 변경 등. 건강 상태가 없음이면 운동 목표 기반으로만 작성.",
    "total_estimated_cost": 0,
    "market_prices": [
        {{
            "name": "재료명",
            "recipe_amount": "레시피상 사용량",
            "market_unit": "마트 판매 단위",
            "market_price": 0,
            "calculation_reasoning": "1망(10개)에 5000원이므로 1개당 500원. 레시피에서 2개 사용하므로 1000원",
            "calculated_cost": 0
        }}
    ]
}}
"""

def get_recipe_prompt():
    return ChatPromptTemplate.from_template(RECIPE_ANALYST_TEMPLATE)