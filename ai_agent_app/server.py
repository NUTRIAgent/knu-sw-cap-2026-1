# fastapi.py (파일명을 가급적 app_server.py 등으로 바꾸는 걸 추천해요!)
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import List
import os
from langchain_openai import ChatOpenAI
from dotenv import load_dotenv
import asyncio
# 분리된 클래스들을 가져옵니다 (파일명에 맞춰 임포트 경로 수정 필요)
from ai_agent_app.DataLoader import RecipeDataLoader
from ai_agent_app.GetMarketPrices import GetMarketPrices
from ai_agent_app.SelectCandidates import SelectCandidates
from ai_agent_app.ProcessDynamicInputs import ProcessDynamicInputs

load_dotenv()
app = FastAPI(title="Recipe AI API")

class UserRequest(BaseModel):
    height_cm: float = Field(..., gt=0, example=180.5)
    weight_kg: float = Field(..., gt=0, example=85.0)
    location: str = Field(..., example="관악구")
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
    

recipe_path = "ai_agent_app/all_recipe_nutrition_data.json"
price_path = "ai_agent_app/seoul_prices_weekly_2026-04-05.json"

recipes = RecipeDataLoader.load_json(recipe_path)
price_list = RecipeDataLoader.load_json(price_path)

model = ChatOpenAI(
            # OpenRouter 공식 엔드포인트
            base_url="https://openrouter.ai/api/v1", 
            # OpenRouter에서 제공하는 모델 식별자 (예: gpt-4o, claude-3.5-sonnet 등)
            model="openai/gpt-4o", 
            temperature=0, 
            openai_api_key=os.getenv("OPENROUTER_API_KEY"),
            # OpenRouter 권장 필수 헤더 (선택 사항이지만 넣는 것이 좋습니다)
            default_headers={
                "HTTP-Referer": "http://localhost:3000", # 앱의 URL
                "X-Title": "Recipe Analyst App"          # 앱 이름
            }
        )

get_market_prices = GetMarketPrices(price_list)
select_candidates = SelectCandidates(model)

# 메인 오케스트레이터 생성
orchestrator = ProcessDynamicInputs(
    recipes=recipes,
    get_market_prices=get_market_prices,
    select_candidates=select_candidates,
    model=model
)

@app.post("/recommend")
async def get_recommendation(user_input: UserRequest):
    try:
        final_result: dict = await asyncio.get_running_loop().run_in_executor(
            None, orchestrator.process_dynamic_inputs, user_input.dict()
        )

        if "market_prices" in final_result and isinstance(final_result["market_prices"], list):
            # 각 항목의 calculated_cost를 정수로 변환하여 합산
            total_cost = sum(
                float(item.get("calculated_cost", 0)) 
                for item in final_result["market_prices"]
            )
            # 최종 필드 업데이트
            final_result["total_estimated_cost"] = total_cost
        return final_result 
    except ValueError as e:
        # ID 범위 오류, JSON 파싱 실패 등 orchestrator 내부에서 명시적으로 던진 오류
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI 에이전트 실행 중 오류 발생: {str(e)}")
