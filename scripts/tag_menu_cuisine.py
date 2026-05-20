"""
menus 테이블의 category 컬럼을 한식/중식/일식/양식/동남아식/기타 로 재태깅하는 스크립트.

실행 방법:
  # 결과만 확인 (DB 변경 없음)
  python3 scripts/tag_menu_cuisine.py

  # 실제 DB에 반영
  python3 scripts/tag_menu_cuisine.py --apply

환경변수:
  OPENROUTER_API_KEY  (LLM 2차 분류에 필요)
"""

import os
import sys
import json
import re
from collections import Counter
from typing import Optional

import pymysql

# ── DB 연결 설정 ──────────────────────────────────────────────
DB_CONFIG = {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "ai_meal_assistant_123!",
    "database": "meal_assistant",
    "charset": "utf8mb4",
}

# ── 1차 규칙 기반 키워드 매핑 ──────────────────────────────────
# 메뉴명에 해당 키워드가 포함되면 해당 카테고리로 분류
# 순서가 중요: 앞에서 매칭되면 뒤는 보지 않음
CUISINE_RULES: list[tuple[str, list[str]]] = [
    ("중식", [
        "짜장", "짬뽕", "탕수육", "마파두부", "볶음밥", "깐풍", "유린기",
        "팔보채", "고추잡채", "동파육", "마라", "훠궈", "딤섬",
    ]),
    ("일식", [
        "초밥", "스시", "라멘", "우동", "소바", "돈가스", "가츠",
        "오야코", "가라아게", "규동", "텐동", "치라시", "미소",
        "덴푸라", "야키토리", "타코야키",
    ]),
    ("양식", [
        "파스타", "스테이크", "피자", "리조또", "오믈렛", "그라탕",
        "카르보나라", "뇨끼", "펜네", "라자냐", "함박", "크림수프",
        "비프스튜", "포크찹", "샌드위치", "바게트", "프렌치토스트",
    ]),
    ("동남아식", [
        "팟타이", "쌀국수", "커리", "카레", "볶음면", "분짜", "반미",
        "나시고렝", "똠얌", "월남쌈", "가오팟", "아도보",
    ]),
    # 한식은 마지막 — 위에서 매칭 안 된 것은 대부분 한식
    ("한식", [
        "김치", "된장", "불고기", "비빔", "제육", "삼겹", "갈비", "찌개",
        "국밥", "나물", "잡채", "떡볶이", "부침", "전", "조림", "무침",
        "냉면", "국수", "수제비", "설렁탕", "삼계탕", "곰탕", "순대",
        "떡국", "쌈밥", "청국장", "도토리묵", "오징어", "낙지", "꼴뚜기",
        "갈치", "고등어", "삼치", "북어", "황태", "동태", "홍합", "바지락",
        "해물", "새우", "굴", "감자", "고구마", "호박", "시금치", "깻잎",
        "두부", "계란", "닭볶음", "닭갈비", "대구", "명태", "아귀",
        "육개장", "추어탕", "선지", "뼈다귀", "갈비탕", "미역", "콩나물",
        "만두", "떡만두",
    ]),
]


def classify_by_rule(name: str) -> Optional[str]:
    for cuisine, keywords in CUISINE_RULES:
        for kw in keywords:
            if kw in name:
                return cuisine
    return None


def classify_batch_by_llm(names: list[str]) -> dict[str, str]:
    """메뉴명 리스트를 LLM으로 분류. 실패 시 빈 dict 반환."""
    try:
        from langchain_openai import ChatOpenAI
    except ImportError:
        print("  [경고] langchain-openai 미설치 → LLM 분류 건너뜀")
        return {}

    api_key = os.getenv("OPENROUTER_API_KEY")
    if not api_key:
        print("  [경고] OPENROUTER_API_KEY 환경변수 없음 → LLM 분류 건너뜀")
        return {}

    model = ChatOpenAI(
        base_url="https://openrouter.ai/api/v1",
        model="openai/gpt-4o-mini",
        temperature=0,
        openai_api_key=api_key,
        default_headers={
            "HTTP-Referer": "http://localhost",
            "X-Title": "NutriAgent Menu Tagger",
        },
    )

    menu_list = "\n".join(f"{i + 1}. {n}" for i, n in enumerate(names))
    prompt = (
        "다음은 요리 메뉴명 목록이야. 각 메뉴를 한식/중식/일식/양식/동남아식/기타 중 하나로 분류해줘.\n"
        "반드시 아래 JSON 형식으로만 응답해 (설명 없이):\n"
        '{"메뉴명": "분류", ...}\n\n'
        f"메뉴 목록:\n{menu_list}"
    )

    try:
        response = model.invoke(prompt)
        content = response.content
        match = re.search(r"\{.*\}", content, re.DOTALL)
        if match:
            return json.loads(match.group())
    except Exception as e:
        print(f"  [LLM 오류] {e}")
    return {}


def main(apply: bool) -> None:
    conn = pymysql.connect(**DB_CONFIG)
    cursor = conn.cursor()

    cursor.execute("SELECT id, name FROM menus ORDER BY id")
    menus: list[tuple[int, str]] = cursor.fetchall()
    print(f"총 메뉴: {len(menus)}개\n")

    # ── 1차: 규칙 기반 ───────────────────────────────────────
    updates: dict[int, tuple[str, str]] = {}  # id → (name, cuisine)
    unclassified: list[tuple[int, str]] = []

    for menu_id, name in menus:
        cuisine = classify_by_rule(name)
        if cuisine:
            updates[menu_id] = (name, cuisine)
        else:
            unclassified.append((menu_id, name))

    print(f"[1차 규칙 기반]  분류 완료: {len(updates)}개  /  미분류: {len(unclassified)}개")

    # ── 2차: LLM (미분류만) ──────────────────────────────────
    if unclassified:
        print(f"\n[2차 LLM 분류] 미분류 {len(unclassified)}개 처리 중...")
        BATCH = 50
        for i in range(0, len(unclassified), BATCH):
            chunk = unclassified[i: i + BATCH]
            names_only = [n for _, n in chunk]
            end = min(i + BATCH, len(unclassified))
            print(f"  배치 {i + 1}~{end} / {len(unclassified)}")

            result = classify_batch_by_llm(names_only)
            for menu_id, name in chunk:
                cuisine = result.get(name) or "기타"
                updates[menu_id] = (name, cuisine)

    # ── 결과 요약 ────────────────────────────────────────────
    counter = Counter(v[1] for v in updates.values())
    print("\n[분류 결과]")
    for cuisine, count in sorted(counter.items(), key=lambda x: -x[1]):
        print(f"  {cuisine:8s}: {count:4d}개")

    if not apply:
        print("\n[DRY RUN] DB 변경 없음. 실제 반영하려면 --apply 옵션을 붙여서 실행하세요.")
        cursor.close()
        conn.close()
        return

    # ── DB 업데이트 ──────────────────────────────────────────
    print(f"\n[DB 업데이트] {len(updates)}개 메뉴 category 컬럼 갱신 중...")
    for menu_id, (_, cuisine) in updates.items():
        cursor.execute("UPDATE menus SET category = %s WHERE id = %s", (cuisine, menu_id))

    conn.commit()
    print("완료!")
    cursor.close()
    conn.close()


if __name__ == "__main__":
    main(apply="--apply" in sys.argv)
