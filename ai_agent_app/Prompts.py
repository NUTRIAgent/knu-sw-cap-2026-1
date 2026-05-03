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
- 영양 데이터: {nutrition_info}
- 메뉴 이미지: {main_img}
- 나트륨 팁: {na_tip}
- 레시피 조리과정: {recipe_steps}
- 프로필: {user_profile}
- 제한사항: {user_restrictions}


# 반드시 아래 JSON 구조를 지키세요:
{{
    "menu_name": {menu_name},
    "main_image": {main_img},
    "selection_reason": "선택 이유",
    "total_estimated_cost": 0,
    "market_prices": [
        {{
            "name": "재료명",
            "recipe_amount": "레시피상 사용량",
            "market_unit": "마트 판매 단위",
            "market_price": 0,
            "calculated_cost": 0,
        }}
    ],
    "nutrition": {nutrition_info},
    "recipe_steps": [
        {recipe_steps}
    ],
    "health_tip" : {na_tip}
}}
"""

def get_recipe_prompt():
    return ChatPromptTemplate.from_template(RECIPE_ANALYST_TEMPLATE)