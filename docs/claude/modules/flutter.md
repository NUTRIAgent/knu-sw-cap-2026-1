# Module: flutter_app (Flutter)

## 한 줄 설명

Flutter 기반 **모바일/클라이언트 앱**입니다.

## 주요 명령어(확인된 것만)

레포에 `flutter_app/pubspec.yaml`이 존재합니다.

- 패키지 받기: `flutter pub get`
- 정적 분석: `flutter analyze`
- 테스트: `flutter test`
- 실행: `flutter run`
- 포맷: `dart format .`

## 코드 스타일/규칙(실행 가능)

- 변경 후 최소 1회는 `flutter analyze`를 통과시키는 것을 목표로 함
- UI 변경은 스크린샷/화면 영향 범위를 요약

## 주의사항(실수 방지)

- API 엔드포인트/토큰 저장 방식 변경은 로그인/세션에 영향 → 변경 전후 동작을 짧게 정리
