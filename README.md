# NUTRIAgent

AI 기반 맞춤형 식단 추천 서비스. 사용자의 신체 정보, 건강 목표, 예산, 알러지를 바탕으로 레시피를 추천하고 실시간 시장 가격으로 재료비를 산출합니다.

---

## 시스템 구성

```
Flutter App (클라이언트)
    │
    ├── Spring Boot API (포트 8080)  ← 인증, 사용자 정보, 메뉴 후보 제공
    │       │
    │       └── MySQL DB
    │
    ├── Python AI 서버 (포트 8000)   ← 메뉴 선정 + 레시피 분석
    │
    └── Spring Boot 배치 서버         ← KAMIS 물가 수집 (스케줄러)
```

---

## 데이터 흐름

### 추천 요청 흐름

```
[Flutter] 추천 버튼 클릭
    │
    ├── 1. GET /api/menus/candidates  →  [Spring API]
    │         JWT 있으면 사용자 알러지·선호 기반 필터링
    │         없으면 랜덤 100개 반환
    │         응답: 메뉴 ID·이름·영양정보·재료 텍스트
    │
    ▼
[Flutter] 후보 목록 즉시 화면 표시 (빠름)
    │
    └── 2. POST /recommend  →  [Python AI 서버]
              요청: 신체정보·예산·목표·알러지·선호·JWT
                │
                ├── /api/menus/candidates 재조회 (AI 포맷 변환)
                ├── SelectCandidates: LLM이 후보 중 10개 추림
                ├── GetMarketPrices: 재료별 물가 조회 (현재 미연결)
                ├── ProcessDynamicInputs: LLM이 최종 1개 선정
                └── Prompts chain: 선정 이유 + 재료비 계산 생성
              응답: 메뉴명·영양정보·조리법·선정 이유·재료비 내역

[Flutter] AI 1픽 결과를 후보 목록 상단에 표시
```

### KAMIS 물가 수집 흐름 (배치)

```
[KamisPriceScheduler] 매일 cron 실행
    │
    ├── KamisNaturePriceListClient: KAMIS API XML 요청
    ├── KamisNaturePriceListXmlParser: XML → 가격 항목 파싱
    ├── KamisIngredientMapLoader: 재료명 ↔ KAMIS 품목코드 매핑
    └── KamisPriceUpdateService: ingredient_prices 테이블 upsert
                                  (1g당 가격으로 표준화 저장)
```

### 레시피 데이터 적재 흐름 (배치)

```
[MfdsRecipeImportCommand] 1회성 실행
    │
    ├── FoodSafetyApiFetcher: 식품의약품안전처 API 호출
    ├── RecipeDataParser: JSON → 레시피 파싱
    └── RecipeDataSyncService: menus · menu_ingredients 테이블 적재
```

---

## 모듈별 역할

### `ai-meal-assistant-backend/` — Spring Boot API 서버

| 도메인 | 주요 기능 |
|---|---|
| `user` | 회원가입·로그인·JWT 발급, 신체 정보(키·몸무게·인바디), 식단 선호(목표·예산·채식·매운맛) |
| `menu` | 메뉴 후보 목록 제공 (`/api/menus/candidates`), 사용자 알러지·선호 기반 필터링 |
| `history` | 추천 이력 저장 (`recommendation_logs`) |

### `ai-meal-assistant-batch/` — Spring Boot 배치 서버

| 잡 | 주요 기능 |
|---|---|
| `kamis` | KAMIS API에서 전통시장 농수산물 시세 수집 → `ingredient_prices` 저장 |
| `mfds` | 식품의약품안전처 레시피 API → `menus`, `menu_ingredients` 적재 |
| `seed` | 재료 시드 데이터 초기 적재 |

### `ai_agent_app/` — Python AI 서버 (FastAPI)

| 파일 | 역할 |
|---|---|
| `server.py` | FastAPI 엔드포인트 (`POST /recommend`), Spring API에서 레시피 조회 |
| `MenuFetcher.py` | Spring `/api/menus/candidates` 호출 → AI 내부 포맷(`RCP_NM`, `INFO_ENG` 등)으로 변환 |
| `SelectCandidates.py` | LLM으로 후보 100개 → 상위 10개 추림 |
| `GetMarketPrices.py` | 재료 텍스트에서 키워드 추출 → 물가 데이터에서 가격 조회 |
| `ProcessDynamicInputs.py` | 전체 AI 파이프라인 오케스트레이션 |
| `Prompts.py` | 레시피 분석 + 재료비 계산 LLM 프롬프트 |

### `flutter_app/` — Flutter 클라이언트

| 화면 | 기능 |
|---|---|
| `LoginScreen` | 이메일·소셜 로그인 선택 |
| `SignupScreen` | 회원가입 |
| `OnboardingScreen` | 최초 프로필 입력 (신체정보·목표·선호) |
| `DashboardScreen` | 날씨 브리핑·예산 표시, 추천 버튼 |
| `RecommendationScreen` | 후보 목록 즉시 표시 + AI 1픽 비동기 로딩 |
| `MypageScreen` | 프로필 조회·수정 |

---

## DB 테이블 구조 (주요)

```
menus                  레시피 (이름·카테고리·영양정보·이미지·건강팁)
menu_ingredients       메뉴 ↔ 재료 연결 (사용량 텍스트 포함)
ingredients            재료 마스터 (이름·단위)
ingredient_prices      재료별 시세 (1g당 가격, 날짜, 출처)
users                  회원
user_health_profiles   신체 정보 (키·몸무게·BMI·기초대사량 등)
user_preferences       식단 선호 (예산·채식 타입·단백질 수준·운동 목표)
user_allergies         알러지 정보
user_food_preferences  음식 선호 키워드
recommendation_logs    추천 이력
```

---

## 환경 변수

### AI 서버 (`ai_agent_app/.env`)
```
OPENROUTER_API_KEY=sk-or-v1-...   # OpenRouter API 키 (gpt-4o-mini 사용)
BACKEND_URL=http://localhost:8080  # Spring API 주소
```

### 배치 서버 (`application.yml` 또는 환경변수)
```
KAMIS_API_KEY=...       # KAMIS API 인증키
```

---

## 실행 방법

```bash
# Spring API 서버
cd ai-meal-assistant-backend
./gradlew bootRun

# Spring 배치 서버
cd ai-meal-assistant-batch
./gradlew bootRun

# Python AI 서버
cd ai_agent_app
pip install -r requirements.txt
uvicorn ai_agent_app.server:app --reload --port 8000

# Flutter 앱
cd flutter_app
flutter run
```

---

## 현재 미구현 / 향후 작업

### 높은 우선순위

- [ ] **KAMIS 물가 → AI 서버 연동**
  - 현재: `GetMarketPrices([])` 빈 리스트로 초기화 → LLM이 가격 추정
  - 필요: Spring API에 `/api/ingredients/prices` 엔드포인트 추가 → AI 서버가 실시간 시세 조회
  - 관련 파일: `GetMarketPrices.py`, `server.py`, `IngredientPriceRepository.java`

- [ ] **레시피 조리 단계 DB 저장**
  - 현재: `menu_steps` 테이블 없음 → `MenuCandidateDto.steps` 항상 빈 리스트 반환
  - 필요: 배치 서버에서 MFDS 데이터의 `MANUAL01~MANUAL20` 필드 파싱 → `menu_steps` 테이블 적재
  - 관련 파일: `MfdsRecipeImportService.java`, `MenuCandidateDto.java`, `MenuFetcher.py`

- [ ] **건강 상태(지병) 필드 추가**
  - 현재: `health_conditions` 빈 리스트로 고정 (`UserHealthProfile`에 해당 필드 없음)
  - 필요: `UserHealthProfile`에 당뇨·고혈압 등 지병 필드 추가, 온보딩·마이페이지 UI 연결
  - 관련 파일: `UserHealthProfile.java`, `UserProfileRequest.java`, `onboarding_screen.dart`, `mypage_screen.dart`

### 중간 우선순위

- [ ] **추천 이력 저장**
  - `recommendation_logs` 테이블은 존재하나 AI 추천 결과를 실제로 저장하는 로직 미구현
  - AI 서버 응답 성공 시 Spring API로 이력 저장 호출 필요

- [ ] **대시보드 날씨 실시간 연동**
  - 현재: "서울시 맑음 22°C" 하드코딩
  - 필요: 날씨 API(기상청 or OpenWeatherMap) 연동, 날씨 기반 브리핑 문구 동적 생성

- [ ] **대시보드 예산 카드 수정 기능**
  - 수정 버튼 UI는 있으나 동작 미구현 (`IconButton(onPressed: () {}`)

- [ ] **사용자 위치 정보**
  - 현재: `location`은 "서울"로 하드코딩
  - 필요: `UserPreference`에 지역 필드 추가, 물가 조회 지역화에 활용

### 낮은 우선순위

- [ ] **소셜 로그인 (카카오/구글)**
  - `LoginScreen`에 버튼만 존재, OAuth 연동 미구현

- [ ] **인바디 연동 온보딩**
  - `UserHealthProfile`에 `skeletalMuscleMass`, `inbodyScore` 등 인바디 필드는 있으나 입력 UI 없음

- [ ] **AI 추천 재시도 / 다른 메뉴 보기**
  - 현재 추천 화면에서 한 번만 호출, 재추천 기능 없음

- [ ] **오프라인 / 에러 처리 고도화**
  - AI 서버 타임아웃(120초) 시 사용자 피드백 개선 필요
