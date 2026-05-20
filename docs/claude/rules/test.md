# Testing Rules

1. **Framework**: JUnit 5, AssertJ, Mockito 기반.
2. **Naming Convention**:
    - 테스트 메서드명은 한글로 목적과 예상 결과를 명확히 작성 (예: `void 물가가_없으면_기본값을_반환한다()`).
3. **Structure (BDD)**:
    - 모든 테스트 코드 내부는 `// Given`, `// When`, `// Then` 주석으로 구역을 나누어 가독성 확보.
4. **Scope**:
    - JPA/DB 테스트는 `@DataJpaTest`로 가볍게.
    - 외부 API 연동 테스트는 Mocking 처리하여 실제 외부 망 호출을 차단할 것.