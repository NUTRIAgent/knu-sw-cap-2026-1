from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import List, Optional
import os
from langchain_openai import ChatOpenAI
from dotenv import load_dotenv
import asyncio
from ai_agent_app.GetMarketPrices import GetMarketPrices
from ai_agent_app.SelectCandidates import SelectCandidates
from ai_agent_app.ProcessDynamicInputs import ProcessDynamicInputs
from ai_agent_app.MenuFetcher import MenuFetcher

load_dotenv()
app = FastAPI(title="Recipe AI API")


class UserRequest(BaseModel):
    height_cm: float = Field(..., gt=0, example=180.5)
    weight_kg: float = Field(..., gt=0, example=85.0)
    location: str = Field(..., example="서울")
    budget: float = Field(..., gt=0, example=8000)

    health_conditions: List[str] = Field(
        default_factory=list,
        example=["고혈압"],
        description="사용자의 지병이나 주의가 필요한 건강 상태"
    )
    fitness_goal: str = Field(
        default="일반식단",
        example="근력운동",
        description="운동 목적: 다이어트, 근력운동, 유지 등"
    )

    allergies: List[str] = Field(default_factory=list, example=["견과류", "메밀"])
    preferences: List[str] = Field(default_factory=list, example=["매운맛"])

    jwt_token: Optional[str] = Field(
        default=None,
        description="Spring 백엔드 JWT. 제공 시 서버 사이드 필터링 후보 사용"
    )


BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:8080")
menu_fetcher = MenuFetcher(BACKEND_URL)

model = ChatOpenAI(
    base_url="https://openrouter.ai/api/v1",
    model="openai/gpt-4o-mini",   # gpt-4o → gpt-4o-mini: 속도 개선
    temperature=0,
    openai_api_key=os.getenv("OPENROUTER_API_KEY"),
    default_headers={
        "HTTP-Referer": "http://localhost:3000",
        "X-Title": "Recipe Analyst App"
    }
)

get_market_prices = GetMarketPrices([])  # 가격 데이터는 추후 DB 연결
select_candidates = SelectCandidates(model)

orchestrator = ProcessDynamicInputs(
    recipes=[],  # 런타임에 항상 주입되므로 빈 리스트
    get_market_prices=get_market_prices,
    select_candidates=select_candidates,
    model=model
)


def _resolve_recipes(jwt_token: Optional[str]) -> list:
    """Spring /api/menus/candidates 에서 AI 포맷 후보 리스트 반환."""
    candidates = menu_fetcher.fetch_candidates_full(jwt_token)
    if not candidates:
        print("[server] Spring 후보 조회 실패")
    return candidates


@app.post("/recommend")
async def get_recommendation(user_input: UserRequest):
    try:
        active_recipes = _resolve_recipes(user_input.jwt_token)
        if not active_recipes:
            raise ValueError("메뉴 후보를 가져올 수 없습니다. Spring 백엔드 연결을 확인하세요.")

        user_query = user_input.dict(exclude={"jwt_token"})

        final_result: dict = await asyncio.get_running_loop().run_in_executor(
            None, orchestrator.process_dynamic_inputs, user_query, active_recipes
        )

        if "market_prices" in final_result and isinstance(final_result["market_prices"], list):
            total_cost = sum(
                float(item.get("calculated_cost", 0))
                for item in final_result["market_prices"]
            )
            final_result["total_estimated_cost"] = total_cost

        return final_result
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI 에이전트 실행 중 오류 발생: {str(e)}")
