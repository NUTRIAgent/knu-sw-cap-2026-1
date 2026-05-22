from typing import List, Dict
from GoalGuidelines import format_guideline


def format_enriched(cid, recipe: Dict, price_info: str, rough_cost: int = 0) -> str:
    """enriched 문자열 포맷 (rank_node 프롬프트용)"""
    cost_str = f"{rough_cost}원" if rough_cost > 0 else "추정불가"
    return (
        f"ID:{cid} | 메뉴:{recipe['RCP_NM']} | 추정조리비:{cost_str} | "
        f"열량:{recipe['INFO_ENG']}kcal 단백질:{recipe['INFO_PRO']}g "
        f"지방:{recipe['INFO_FAT']}g 탄수화물:{recipe['INFO_CAR']}g 나트륨:{recipe['INFO_NA']}mg"
    )


def parse_recipe_steps(recipe: Dict) -> List[Dict]:
    """레시피 단계 파싱 (desc 있는 단계만 포함)"""
    steps = []
    for i in range(1, 21):
        num = str(i).zfill(2)
        desc = recipe.get(f"MANUAL{num}", "").strip()
        img = recipe.get(f"MANUAL_IMG{num}", "").strip()
        if desc:
            steps.append({"step_no": i, "content": desc, "image": img})
    return steps


def build_static_data(recipe: Dict) -> Dict:
    """정적 레시피 데이터 조립 (LLM 호출 없이 구성 가능한 필드)"""
    return {
        "recipe_id": recipe.get("MENU_ID") or recipe.get("RCP_SEQ"),  # Spring MENU_ID 우선, 폴백으로 RCP_SEQ
        "menu_name": recipe["RCP_NM"],
        "main_img": recipe["ATT_FILE_NO_MAIN"],
        "nutrition_info": {
            "energy": f"{recipe['INFO_ENG']}kcal",
            "protein": f"{recipe['INFO_PRO']}g",
            "fat": f"{recipe['INFO_FAT']}g",
            "carbs": f"{recipe['INFO_CAR']}g",
            "sodium": f"{recipe['INFO_NA']}mg",
        },
        "recipe_steps": parse_recipe_steps(recipe),
        "na_tip": recipe["RCP_NA_TIP"],
    }


def build_llm_input(recipe: Dict, price_info: str, user_query: Dict) -> Dict:
    """LLM chain에 넘길 입력 딕셔너리 조립"""
    return {
        "menu_name": recipe["RCP_NM"],
        "ingredients": recipe["RCP_PARTS_DTLS"],
        "price_info": price_info,
        "user_profile": (
            f"키 {user_query.get('height_cm')}cm, "
            f"체중 {user_query.get('weight_kg')}kg, "
            f"운동 목표: {user_query.get('fitness_goal', '일반식단')}, "
            f"건강 상태: {', '.join(user_query.get('health_conditions', []) or []) or '없음'}, "
            f"선호 음식: {', '.join(user_query.get('preferences', []) or []) or '없음'}"
        ),
        "user_restrictions": (
            f"알러지: {', '.join(user_query.get('allergies', []) or [])}, "
            f"선호: {', '.join(user_query.get('preferences', []) or [])}"
        ),
        "health_conditions": ', '.join(user_query.get('health_conditions', []) or []) or '없음',
        "goal_guideline": format_guideline(user_query.get('fitness_goal', '일반식단')),
    }