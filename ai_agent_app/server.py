from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from typing import List, Optional
import os
import json
from langchain_openai import ChatOpenAI
from dotenv import load_dotenv

# 데이터 로더
from ai_agent_app.DataLoader import RecipeDataLoader
from ai_agent_app.GetMarketPrices import GetMarketPrices
from ai_agent_app.SelectCandidates import SelectCandidates
from ai_agent_app.MenuFetcher import MenuFetcher
from ai_agent_app.UserHistoryManager import UserHistoryManager

# 그래프 및 서비스
from ai_agent_app.RecipeGraph import RecipeGraphBuilder
from ai_agent_app.services import (
    FeedbackAnalyzer,
    RecommendationEngine,
    RecommendationService,
)
from ai_agent_app.session_manager import SessionManager

# =====================================================================
# 초기화
# =====================================================================
load_dotenv()
app = FastAPI(title="Recipe AI API")


# Spring 백엔드 연동
BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:8080")
menu_fetcher = MenuFetcher(BACKEND_URL)

# LLM 모델 초기화
model = ChatOpenAI(
    base_url="https://openrouter.ai/api/v1",
    model="openai/gpt-4o-mini",
    temperature=0,
    openai_api_key=os.getenv("OPENROUTER_API_KEY"),
    default_headers={
        "HTTP-Referer": "http://localhost:3000",
        "X-Title": "Recipe Analyst App",
    },
)

# 헬퍼 클래스들
get_market_prices = GetMarketPrices([])
select_candidates = SelectCandidates(model)

# 그래프 및 서비스 초기화
graph_builder = RecipeGraphBuilder(
    get_market_prices=get_market_prices,
    select_candidates=select_candidates,
    model=model,
)

user_history_manager = UserHistoryManager()
session_manager = SessionManager()
recommendation_engine = RecommendationEngine(graph_builder)
feedback_analyzer = FeedbackAnalyzer(model)
recommendation_service = RecommendationService(
    recommendation_engine, feedback_analyzer, session_manager
)

# =====================================================================
# Pydantic 모델
# =====================================================================


class UserRequest(BaseModel):
    height_cm: float = Field(..., gt=0, example=180.5)
    weight_kg: float = Field(..., gt=0, example=85.0)
    location: str = Field(default="서울", example="서울", description="사용자 위치 (지역별 물가 조회에 사용)")
    budget: float = Field(..., gt=0, example=8000)
    health_conditions: List[str] = Field(
        default_factory=list,
        example=["고혈압"],
        description="사용자의 지병이나 주의가 필요한 건강 상태",
    )
    fitness_goal: str = Field(
        default="일반식단",
        example="근력운동",
        description="운동 목적: 다이어트, 근력운동, 유지 등",
    )
    allergies: List[str] = Field(
        default_factory=list, example=["견과류", "메밀"]
    )
    preferences: List[str] = Field(
        default_factory=list, example=["매운맛"]
    )
    jwt_token: Optional[str] = Field(
        default=None,
        description="Spring 백엔드 JWT. 제공 시 서버 사이드 필터링 후보 사용"
    )
    candidate_menu_ids: Optional[List[int]] = Field(
        default=None,
        description="Flutter가 미리 조회한 후보 메뉴 ID 목록. 제공 시 해당 후보만 사용하여 Flutter와 동일한 후보 풀 보장"
    )


class HistoryRequest(BaseModel):
    jwt_token: Optional[str] = Field(default=None, description="Spring 백엔드 JWT")
    recipe_id: str = Field(..., description="먹은 레시피 RCP_SEQ")
    recipe_name: str = Field(..., description="먹은 메뉴 이름")
    comment: str = Field(default="", description="코멘트")
    rating: float = Field(..., ge=1, le=5, description="별점 (1~5)")
    # 당시 사용자 컨텍스트 (선택) — 저장 시 같이 임베딩되어 검색 품질 향상
    fitness_goal: Optional[str] = Field(default=None, description="당시 운동 목표")
    health_conditions: List[str] = Field(default_factory=list, description="당시 건강 상태")
    preferences: List[str] = Field(default_factory=list, description="당시 선호")


class FeedbackRequest(BaseModel):
    jwt_token: Optional[str] = Field(default=None, description="Spring 백엔드 JWT (세션 식별용)")
    rejected_recipe_ids: List[str] = Field(
        ..., description="거절한 레시피 RCP_SEQ 리스트"
    )
    reason: str = Field(default="", description="거절 이유")


def _user_id_from_jwt(jwt_token: Optional[str]) -> str:
    """JWT의 sub(이메일)을 user_id로 사용. 토큰 없으면 anonymous."""
    if not jwt_token:
        return "anonymous"
    try:
        import base64, json
        payload_b64 = jwt_token.split(".")[1]
        payload_b64 += "=" * (-len(payload_b64) % 4)
        payload = json.loads(base64.urlsafe_b64decode(payload_b64))
        return payload.get("sub", "anonymous")
    except Exception:
        return "anonymous"


def _resolve_recipes(jwt_token: Optional[str], candidate_menu_ids: Optional[List[int]] = None) -> list:
    """후보 메뉴 목록 반환.
    - candidate_menu_ids 제공 시: 해당 IDs로 조회 (Flutter와 동일한 후보 풀 보장)
    - 미제공 시: 전체 후보 조회
    """
    if candidate_menu_ids:
        candidates = menu_fetcher.fetch_candidates_by_ids(candidate_menu_ids, jwt_token)
        if candidates:
            return candidates
        print("[server] ID 기반 후보 조회 실패 → 전체 후보로 대체")

    candidates = menu_fetcher.fetch_candidates_full(jwt_token)
    if candidates:
        return candidates
    return []


# =====================================================================
# 엔드포인트
# =====================================================================


@app.post("/recommend")
async def get_recommendation(user_input: UserRequest):
    """
    초기 추천 요청 (SSE 스트리밍)

    Returns text/event-stream:
        각 분석 완료 시마다 `data: {...}\n\n` 전송
        마지막에 `data: [DONE]\n\n`
    """
    try:
        user_id = _user_id_from_jwt(user_input.jwt_token)
        active_recipes = _resolve_recipes(user_input.jwt_token, user_input.candidate_menu_ids)
        if not active_recipes:
            raise HTTPException(status_code=422, detail="메뉴 후보를 가져올 수 없습니다. Spring 백엔드 연결을 확인하세요.")

        user_query = user_input.dict(exclude={"jwt_token"})
        history_texts = await user_history_manager.search_relevant_history(
            user_id=user_id,
            user_query=user_query,
            k=5,
        )

        session_manager.create_or_get_session(user_id, user_query)

        async def event_generator():
            try:
                async for result in recommendation_engine.stream_initial_recommendations(
                    active_recipes, user_query, history_texts
                ):
                    rid = result.get("recipe_id") or result.get("menu_id")
                    try:
                        result["menu_id"] = int(rid) if rid is not None else 0
                    except (TypeError, ValueError):
                        result["menu_id"] = 0
                    yield f"data: {json.dumps(result, ensure_ascii=False)}\n\n"
            except ValueError as e:
                yield f"data: {json.dumps({'error': str(e)}, ensure_ascii=False)}\n\n"
            except Exception as e:
                yield f"data: {json.dumps({'error': f'AI 에이전트 실행 중 오류: {str(e)}'}, ensure_ascii=False)}\n\n"
            finally:
                yield "data: [DONE]\n\n"

        return StreamingResponse(
            event_generator(),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "X-Accel-Buffering": "no",
            },
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI 에이전트 실행 중 오류 발생: {str(e)}")


@app.post("/history")
async def save_history(req: HistoryRequest):
    """사용자가 먹은 메뉴 + 코멘트 + 별점 저장"""
    try:
        user_id = _user_id_from_jwt(req.jwt_token)
        user_history_manager.save(
            user_id=user_id,
            recipe_id=req.recipe_id,
            recipe_name=req.recipe_name,
            comment=req.comment,
            rating=req.rating,
            context={
                "fitness_goal": req.fitness_goal,
                "health_conditions": req.health_conditions,
                "preferences": req.preferences,
            },
        )
        return {"status": "saved"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/feedback")
async def provide_feedback(feedback: FeedbackRequest):
    """
    피드백 처리 및 재추천

    Args:
        feedback: 피드백 정보 (user_id 포함)

    Returns:
        {
            "user_id": str,
            "feedback_count": int,
            "applied_constraint": str,
            "recommendations": List[Dict]
        }
    """
    try:
        user_id = _user_id_from_jwt(feedback.jwt_token)
        result = await recommendation_service.provide_feedback(
            user_id,
            feedback.rejected_recipe_ids,
            feedback.reason,
        )
        # 일단 가장 적합한 1개만 반환
        result["recommendations"] = result.get("recommendations", [])[:1]
        return result
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
