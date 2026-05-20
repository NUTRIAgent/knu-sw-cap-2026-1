# Project Memory & State

## Known Issues / Watch out
- 공공데이터 특성상 식재료명(`name`) 파싱 예외가 계속 발견될 수 있음. 파서 수정 시 기존 테스트 케이스 파괴 주의.
- `Ingredient` 엔티티의 `standardUnit`, `latestPrice`는 배치 작업 시 채워지므로 초기 적재 시에는 `null` 허용.
