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

### 메뉴 + 재료 전체 적재 (단발성)

식약처 JSON(`cleaned_recipe_data.json`)을 읽어 `menus`, `ingredients`, `menu_ingredients`, `menu_steps`, `menu_allergies` 테이블을 채웁니다. S3 이미지 업로드 포함.

```bash
cd ai-meal-assistant-batch
./gradlew bootRun --args='--batch.seed.ingredients.enabled=true'
```

### 재료만 재적재 (단발성)

`menu_ingredients` 테이블을 재파싱해 재적재합니다. 파싱 로직 수정 후 기존 데이터를 교정할 때 사용합니다. 기존 데이터를 삭제하고 재삽입합니다.

```bash
cd ai-meal-assistant-batch
./gradlew bootRun --args='--batch.seed.recipe-ingredients.enabled=true'
```

### 조리단계만 재적재 (단발성)

`menu_steps` 테이블이 비어있거나 잘못된 경우 steps만 빠르게 재적재합니다. S3 업로드 없이 수 초 내 완료됩니다.

```bash
cd ai-meal-assistant-batch
./gradlew bootRun --args='--batch.seed.steps.enabled=true'
```

## 가격 변동 푸시 알림

### 동작 방식

1. `KamisPriceScheduler`가 매일 가격 갱신 후 `PriceAlertNotificationService.dispatchAlerts()` 자동 호출
2. `originalPrice` 대비 `prevDayPrice` 변동률이 **±3% 이상**인 재료를 감지
3. 해당 재료를 팔로우 중인 사용자의 FCM 토큰으로 알림 발송

### Firebase 서비스 계정 설정

배치 서버에서 FCM을 발송하려면 Firebase 서비스 계정 키 파일이 필요합니다.

1. Firebase 콘솔 → 프로젝트 설정 → 서비스 계정 → **새 비공개 키 생성** → JSON 다운로드
2. 파일을 `src/main/resources/firebase-service-account.json`으로 저장 (`.gitignore` 처리 — **커밋 금지**)
3. 또는 환경변수로 경로 지정:

```bash
FIREBASE_SERVICE_ACCOUNT_PATH=/절대경로/firebase-service-account.json ./gradlew bootRun
```

파일이 없으면 FCM 알림은 스킵되고 나머지 배치는 정상 동작합니다.

### FCM 테스트 엔드포인트 (배치 서버 8081포트)

배치 스케줄을 기다리지 않고 즉시 테스트할 수 있습니다.

#### 특정 기기로 테스트 알림 발송

```bash
curl -X POST "http://localhost:8081/api/admin/fcm/test?token={FCM_토큰}"
```

FCM 토큰은 앱 로그에서 확인하거나 다음 코드로 출력:

```dart
FirebaseMessaging.instance.getToken().then((t) => print('FCM TOKEN: $t'));
```

#### 변동률 알림 수동 트리거

DB에 KAMIS 가격 데이터가 있을 때 즉시 알림 발송:

```bash
curl -X POST "http://localhost:8081/api/admin/fcm/dispatch-alerts"
```

## 멱등성(중복 적재 방지) 가이드

- 권장: 유니크 키 + upsert
- 예: 가격 테이블의 (ingredient_id, price_date, market, unit) 유니크 인덱스

## API 키

아직 미구현 스텁입니다. 구현 시 아래 형태를 권장합니다.

- `KAMIS_API_KEY` (환경변수)
- `MFDS_API_KEY`

## DDL 정책

본 모듈은 현재 `spring.jpa.hibernate.ddl-auto=update`로 설정되어 실행 시 테이블을 자동 생성/갱신합니다.

- 운영 환경에서는 `validate` 또는 마이그레이션 도구(Flyway/Liquibase) 사용을 권장합니다.
