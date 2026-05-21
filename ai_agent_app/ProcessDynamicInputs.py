from langchain_openai import ChatOpenAI
from typing import List, Dict, Any
from langchain_core.output_parsers import JsonOutputParser
from ai_agent_app.GetMarketPrices import GetMarketPrices
from ai_agent_app.SelectCandidates import SelectCandidates
from ai_agent_app.Prompts import get_recipe_prompt
import re

class ProcessDynamicInputs:
    def __init__(self, recipes: List[Dict], get_market_prices: GetMarketPrices, select_candidates: SelectCandidates, model: ChatOpenAI):
        self.recipes = recipes
        self.get_market_prices = get_market_prices
        self.select_candidates = select_candidates
        self.model = model
        self.chain = get_recipe_prompt() | self.model | JsonOutputParser()
        
    def _enrich_candidates(self, candidate_ids, user_location, active_recipes) -> tuple[list[str], dict]:
        """후보별 물가 조회 + enriched 문자열 생성"""
        price_cache: Dict[int, str] = {}
        enriched: List[str] = []
        for cid in candidate_ids:
            r = active_recipes[cid]
            try:
                p_info = self.get_market_prices.get_market_prices(
                    r['RCP_PARTS_DTLS'], 
                    user_district=user_location
                )
            except Exception as e:
                p_info = "가격 데이터 조회 실패"
            price_cache[cid] = p_info
            enriched.append(self._format_enriched(cid, r, p_info))
        return enriched, price_cache
    
    def _format_enriched(self, cid, recipe, price_info) -> str:
        """enriched 문자열 포맷"""
        return (
            f"ID:{cid} | 메뉴:{recipe['RCP_NM']} | 물가:{price_info} | "
            f"열량:{recipe['INFO_ENG']}kcal 단백질:{recipe['INFO_PRO']}g "
            f"지방:{recipe['INFO_FAT']}g 탄수화물:{recipe['INFO_CAR']}g 나트륨:{recipe['INFO_NA']}mg"
        )
        
    def _select_final_id(self, user_query, enriched, candidate_ids) -> int:
        """LLM으로 최종 레시피 ID 선정"""
        final_prompt = (
            f"사용자 예산: {user_query['budget']}원\n"
            f"사용자 목표: {user_query.get('fitness_goal', '일반식단')}\n"
            f"건강 상태: {user_query.get('health_conditions', '없음')}\n"
            f"아래 후보 리스트 중 예산 내에서 사용자 목표와 건강 상태에 가장 적합한 레시피를 하나 선택하세요.\n"
            f"반드시 마지막 줄에 다음 형식으로만 답하세요 (다른 설명 금지):\n"
            f"선택ID: <숫자>\n"
            "----------------------\n"
            + "\n".join(enriched)
        )
        raw = self.model.invoke(final_prompt).content
        match = re.search(r"선택ID:\s*(\d+)", raw)
        if match is None:
            raise ValueError(f"LLM 응답에서 '선택ID:' 앵커를 찾을 수 없습니다. 응답: {raw!r}")


        final_id = int(match.group(1))
        # LLM이 후보 범위 밖의 ID를 반환했을 경우 방어
        if final_id not in candidate_ids:
            raise ValueError(
                f"LLM이 반환한 ID({final_id})가 후보 목록에 없습니다: {candidate_ids}"
            )
        return final_id
        
    def _parse_recipe_steps(self, final_recipe) -> list[dict]:
        """레시피 단계 파싱"""
        recipe_steps = []
        for i in range(1, 21):
            num = str(i).zfill(2)
            desc = final_recipe.get(f'MANUAL{num}', "").strip()
            img = final_recipe.get(f'MANUAL_IMG{num}', "").strip()
            
            # 설명(desc)이 있는 경우에만 리스트에 추가
            if desc:
                recipe_steps.append({
                    "step_no": i, # 실제 데이터상의 단계 번호
                    "content": desc,
                    "image": img
                })
        return recipe_steps
    
    def _build_static_data(self, final_recipe) -> dict:
        """정적 레시피 데이터 조립"""
        return {
            "menu_id": final_recipe.get("MENU_ID"),
            "menu_name": final_recipe["RCP_NM"],
            "main_img": final_recipe["ATT_FILE_NO_MAIN"],
            "nutrition_info": {
                "energy": f"{final_recipe['INFO_ENG']}kcal",
                "protein": f"{final_recipe['INFO_PRO']}g",
                "fat": f"{final_recipe['INFO_FAT']}g",
                "carbs": f"{final_recipe['INFO_CAR']}g",
                "sodium": f"{final_recipe['INFO_NA']}mg",
            },
            "recipe_steps": self._parse_recipe_steps(final_recipe),
            "na_tip": final_recipe["RCP_NA_TIP"],
        }
        
    def _build_llm_data(self, final_recipe, price_info, user_query) -> dict:
        """LLM chain 실행 및 결과 반환"""
        llm_input ={
            "menu_name": final_recipe["RCP_NM"],
            "ingredients": final_recipe["RCP_PARTS_DTLS"],
            "price_info": price_info,  # 캐시 재사용
            "user_profile": (
                f"키 {user_query.get('height_cm')}cm, "
                f"체중 {user_query.get('weight_kg')}kg, "
                f"목표: {user_query.get('fitness_goal')}"
            ),
            "user_restrictions": (
                f"알러지: {', '.join(user_query.get('allergies', []) or [])}, "
                f"선호: {', '.join(user_query.get('preferences', []) or [])}"
            ),
        }
        return self.chain.invoke(llm_input)
    
    def process_dynamic_inputs(self, user_query: Dict, recipes: List[Dict] = None) -> Dict[str, Any]:
        active_recipes = recipes if recipes is not None else self.recipes
        candidate_ids = self.select_candidates.select_candidates(active_recipes, user_query)

        if not candidate_ids:
            raise ValueError("적합한 레시피 후보가 없습니다.")

        enriched, price_cache = self._enrich_candidates(candidate_ids, user_query.get("location"), active_recipes)
        final_id    = self._select_final_id(user_query, enriched, candidate_ids)
        print(f"최종 선정된 레시피 ID: {final_id}")
        final_recipe = active_recipes[final_id]
        
        static_data = self._build_static_data(final_recipe)
        llm_data    = self._build_llm_data(final_recipe, price_cache[final_id], user_query)
        return {**static_data, **llm_data}