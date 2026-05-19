<!--
이 파일은 Claude가 이 레포에서 작업할 때의 “행동 규칙 + 빠른 명령어” 엔트리입니다.
규칙은 짧고 강하게 유지하고, 자세한 안내는 @import 문서로 분리합니다.
-->

# NUTRIAgent (knu-sw-cap-2026-1)

이 프로젝트는 **AI 식단/레시피 서비스**로, **Spring Boot 백엔드 + Spring Boot 배치 + Flutter 앱 + Python AI 에이전트**로 구성된 모노레포입니다.

## 가장 중요한 규칙(반드시)

1) **변경은 ‘제안 → 사용자 승인 → 적용’ 순서로만 진행**
- 코드/설정/문서 변경을 바로 적용하지 말고, 먼저 변경 요약과 영향을 설명한 뒤 승인을 받습니다.

2) **추측 금지(거짓말 금지)**
- 파일 경로/명령/설정/API 동작은 확인된 것만 말합니다.
- 모르면 “확인 필요”로 명시하고, 검색/읽기로 근거를 확보합니다.

3) **DB 쓰기/대량 적재/마이그레이션은 사전 확인 필수**
- 어떤 테이블을 얼마나 바꾸는지(레코드 수/키/유니크 인덱스/롤백) 먼저 설명하고 진행합니다.
- 기본은 dry-run/limit(가능하면) 모드부터.

4) **외부 API(KAMIS 등) 호출은 안전장치 포함**
- 응답 파싱 실패 시 원문 덤프 저장.
- 요청 헤더/WAF/레이트리밋을 고려.
- 키/인증정보는 커밋하지 않습니다(환경변수/시크릿 사용).

## 레포 구조(요약)

- `ai-meal-assistant-backend/`: Spring Boot API 서버
- `ai-meal-assistant-batch/`: Spring Boot 배치 서버(데이터 적재)
- `flutter_app/`: Flutter 클라이언트
- `ai_agent_app/`: Python 기반 AI 에이전트 코드

## 빠른 시작(검증된 명령만)

> 아래 명령은 레포에 `gradlew`, `pubspec.yaml`이 존재하는 것을 확인한 뒤 적었습니다.

- 백엔드 테스트: `ai-meal-assistant-backend/` → `./gradlew test`
- 배치 테스트: `ai-meal-assistant-batch/` → `./gradlew test`
- Flutter 분석/테스트: `flutter_app/` → `flutter analyze`, `flutter test`

## 작업 방식(요약)

- 변경 전: 요구사항 체크리스트 작성 → 관련 코드/설정 읽기 → 영향 범위 정리
- 변경 후: 최소 품질 게이트(Build/Test/Lint 중 가능한 것) 수행 → 결과 요약

@import docs/claude/workflows.md
@import docs/claude/modules/backend.md
@import docs/claude/modules/batch.md
@import docs/claude/modules/flutter.md
