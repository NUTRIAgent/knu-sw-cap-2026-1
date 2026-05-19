# Module: ai-meal-assistant-batch (Spring Boot Batch Server)

## 한 줄 설명

운영 서버와 분리된 **데이터 적재 배치 서버**로, 동일 MySQL을 사용하며 외부 API(KAMIS/식약처) 기반 적재 작업을 수행합니다.

## 주요 명령어(확인된 것만)

레포에 `ai-meal-assistant-batch/gradlew`, `build.gradle`, `src/main/resources/application.yml`이 존재합니다.

- 테스트: `./gradlew test`
- 실행: `./gradlew bootRun`

### (예시) KAMIS 매핑 생성 커맨드

- 실행(실제로 동작 확인함):
  - `./gradlew bootRun --args='--batch.kamis.generate-map=true'`
- 산출물:
  - `build/kamis-ingredient-map.generated.json`

## 코드 스타일/규칙(실행 가능)

- 배치 작업은 “멱등성”을 최우선으로 설계
  - 유니크 키/업서트 기준을 코드+문서로 함께 남김
- 외부 API 파싱 실패 시:
  - 원문(response body)을 `build/` 아래에 덤프(민감정보 마스킹)

## 주의사항(실수 방지)

- 로컬 MySQL이 꺼져 있으면 Spring Boot 기동이 실패할 수 있음(접속 거부/hibernate dialect 미결정).
- 생성된 매핑 JSON은 **후보(topK) + score** 기반일 수 있음.
  - 임계값/확정 규칙 없이 곧바로 `ingredient_prices`에 쓰지 말 것
  - 기본은 dry-run/스킵 로그부터
