# Module: ai-meal-assistant-backend (Spring Boot)

## 한 줄 설명

Spring Boot 기반의 **메인 API 서버**입니다(인증/JWT, JPA, Redis, 외부 연동).

## 주요 명령어(확인된 것만)

레포에 `ai-meal-assistant-backend/gradlew`, `build.gradle`이 존재합니다.

- 테스트: `./gradlew test`
- 실행(로컬): `./gradlew bootRun`

> 배포/도커라이즈/CI는 이 레포에서 명확히 확인되기 전까진 단정하지 않습니다.

## 코드 스타일/규칙(실행 가능)

- Java 17 / Spring Boot 3.4.3 (Gradle 확인)
- 새 코드 추가 시:
  - public API(Controller/DTO)는 validation 어노테이션과 에러 응답을 함께 설계
  - JPA 변경은 엔티티/인덱스/유니크 키 영향까지 함께 설명

## 주의사항(실수 방지)

- Security/JWT 관련 변경은 로그인/인가 플로우에 영향이 크므로, 변경 전에 흐름을 요약해서 공유
- Redis 의존 기능은 로컬 환경에서 미기동 가능성이 있으니, 기동 요구사항을 명확히 남김
