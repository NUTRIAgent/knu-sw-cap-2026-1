import re
from typing import List, Dict, Tuple, Optional
from collections import defaultdict

class GetMarketPrices:
    def __init__(self, price_list: List[Dict]):
        self.price_data_by_district = defaultdict(list)
        for item in price_list:
            district = item.get('M_GU_NAME')
            self.price_data_by_district[district].append(item)
        
        self.index_by_district: Dict[str, Dict[str, Dict]] = {
            district: {p['PRDLST_NM']: p for p in items}
            for district, items in self.price_data_by_district.items()
        }
        # 전국 풀 미리 구축 (지역 미매칭 폴백용)
        all_items = []
        for items in self.price_data_by_district.values():
            all_items.extend(items)
        self._national_pool = all_items
        
        # 상품명별로 가격 모아서 평균 계산
        price_groups = defaultdict(list)
        for p in all_items:
            price_groups[p['PRDLST_NM']].append(p)

        self._national_index = {
            name: {
                **items[0],  # UNIT 등 나머지 필드는 첫 번째 항목 사용
                'A_PRICE': str(round(
                    sum(int(p['A_PRICE']) for p in items) / len(items)
                )),
            }
            for name, items in price_groups.items()
        }
        
    def _get_target_pool(self, user_district: str) -> Tuple[List[Dict], Dict[str, Dict]]:
            if user_district in self.price_data_by_district:
                return (
                    self.price_data_by_district[user_district],
                    self.index_by_district[user_district]
                )
            return self._national_pool, self._national_index
        
    def _match_item(self, word: str, pool: List[Dict], index: Dict[str, Dict]) -> Optional[Dict]:
        """정확히 일치 → 부분 일치 순으로 탐색."""
        if exact := index.get(word):
            return exact
        return next((p for p in pool if word in p['PRDLST_NM']), None)
                
    def get_market_prices(self, ingredients_text: str, user_district: str) -> str:
        try:
            keywords = {
                w for w in re.findall(r'[가-힣]+', ingredients_text)
                if len(w) >= 2
            }
            
            pool, index = self._get_target_pool(user_district)

            results = []
            
            for word in keywords:
                match = self._match_item(word, pool, index)
                if match:
                    results.append(
                        f"- {match['PRDLST_NM']}: {match['A_PRICE']}원 ({match['UNIT']})"
                    )
                    
            print(f"Results: {results}")  # 디버깅용 로그
            return "\n".join(results) if results else "가격 데이터 없음"
        
        except Exception as e:
            print(f"Market Price Search Error: {e}")
            return f"Error: {e}"
        
        