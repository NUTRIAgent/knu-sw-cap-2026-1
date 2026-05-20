# Global Code Style Preferences

## 공통 규칙 (All Modules)
- 변수명과 메서드명은 의미를 명확히 알 수 있게 풀어서 작성한다.
- 불필요한 주석은 지우고 코드로 의도를 표현한다.

## Backend & Batch (Spring Boot / Java)
- **Dependency Injection:** `@Autowired` 절대 금지. `final` + `@RequiredArgsConstructor` 사용.
- **Entity:** 객체 생성은 `@Builder` 패턴만 사용. `@Setter` 사용 금지.
- **JPA:** 연관관계 매핑 시 지연 로딩(`FetchType.LAZY`)을 기본으로 한다.

## Frontend (Flutter / Dart)
- **State Management:** 상태 관리는 Provider(또는 Riverpod)를 기준으로 작성한다.
- **UI Components:** 위젯은 최대한 작게 분리하고, 불필요한 `build()` 호출을 막기 위해 `const` 생성자를 적극 사용한다.
