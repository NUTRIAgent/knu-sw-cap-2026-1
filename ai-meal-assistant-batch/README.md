# ai-meal-assistant-batch

운영(백엔드) 서버와 분리된 배치 서버(Spring Boot)입니다. 동일한 MySQL(DB: `meal_assistant`)을 사용하며 외부 API(KAMIS/식약처) 기반으로 데이터를 적재합니다.

## 요구 환경

- JDK 17
- Gradle Wrapper
- Docker (로컬 MySQL)

## 로컬 DB (docker-compose)

백엔드 모듈의 `docker-compose.yml`을 그대로 사용합니다.

```bash
cd ai-meal-assistant-backend
./gradlew -v # (선택) wrapper 확인
# docker compose up -d
```

## 실행

### 1) 로컬 프로파일 (기본)

- `spring.profiles.default=local`
- DB: `localhost:3306`

```bash
cd ai-meal-assistant-batch
./gradlew bootRun
```

### 2) 도커 네트워크에서 실행 (docker 프로파일)

- DB: 서비스명 `mysql:3306`

```bash
cd ai-meal-assistant-batch
./gradlew bootRun --args='--spring.profiles.active=docker'
```

## 배치 잡

### KAMIS 물가 업데이트 (주기 실행)

- 스케줄러: `KamisPriceScheduler`
- 기본 크론: `0 0 3 * * *` (매일 03:00)
- 설정:
  - `batch.kamis.enabled=true|false`
  - `batch.kamis.cron=...`

### 식약처 레시피/메뉴 업데이트 (단발성)

- CommandLineRunner: `MfdsRecipeImportCommand`
- 기본 비활성화: `batch.mfds.enabled=false`
- 1회 실행:

```bash
cd ai-meal-assistant-batch
./gradlew bootRun --args='--batch.mfds.enabled=true'
```

## 멱등성(중복 적재 방지) 가이드

- 권장: 유니크 키 + upsert
- 예: 가격 테이블의 (ingredient_id, price_date, market, unit) 유니크 인덱스

## API 키

아직 미구현 스텁입니다. 구현 시 아래 형태를 권장합니다.

- `KAMIS_API_KEY`
- `MFDS_API_KEY`

## DDL 정책

본 모듈은 `spring.jpa.hibernate.ddl-auto=validate`로 설정되어 스키마를 변경하지 않습니다.
스키마 변경은 단일 소스(예: 운영 서버 + Flyway)에서 관리하는 것을 권장합니다.
