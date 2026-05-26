# =====================================================================
# 식단 목표별 가이드라인
# =====================================================================

from typing import Dict

GOAL_GUIDELINES: Dict[str, Dict[str, str]] = {
    "다이어트": {
        "calorie": "끼당 400~500kcal 권장 (저칼로리)",
        "macros": "고단백(20g+), 저탄수, 저지방, 식이섬유 풍부",
        "sodium": "나트륨 600mg 이하 권장",
        "focus": "포만감 높고 자극 적은 메뉴 우선. 가공식품/튀김 회피.",
    },
    "근력운동": {
        "calorie": "끼당 700~900kcal 권장 (충분한 에너지)",
        "macros": "고단백(25g+), 충분한 탄수화물, 적당한 지방",
        "sodium": "나트륨 800mg 이하 권장",
        "focus": "근육 합성/회복에 도움되는 단백질원(닭/소/생선/콩) 우선.",
    },
    "체중유지": {
        "calorie": "끼당 600~700kcal 권장",
        "macros": "균형 (탄수화물:단백질:지방 ≈ 5:3:2)",
        "sodium": "나트륨 700mg 이하 권장",
        "focus": "다양한 식재료로 균형 잡힌 식단.",
    },
    "일반식단": {
        "calorie": "끼당 600kcal 내외 (일반 권장량)",
        "macros": "균형 잡힌 영양소",
        "sodium": "나트륨 700mg 이하 권장",
        "focus": "건강하고 맛있는 메뉴.",
    },
}


def get_guideline(goal: str) -> Dict[str, str]:
    return GOAL_GUIDELINES.get(goal, GOAL_GUIDELINES["일반식단"])


def format_guideline(goal: str) -> str:
    g = get_guideline(goal)
    return (
        f"[목표별 영양 가이드: {goal}]\n"
        f"- 권장 칼로리: {g['calorie']}\n"
        f"- 영양소 기준: {g['macros']}\n"
        f"- 나트륨: {g['sodium']}\n"
        f"- 중점: {g['focus']}"
    )
