# API & RESTful Rules

1. **Response Wrapper**:
    - 모든 API 응답은 예외 없이 공통 구조(예: `ApiResponse<T>`)로 감싸서 반환.
    - 실패 시 적절한 HTTP Status와 에러 코드/메시지 규격을 준수.
2. **Endpoint Naming**:
    - 명사형의 복수형 사용 (예: `/api/v1/menus`).
    - 행위(동사)는 URL에 넣지 말고 HTTP Method(GET, POST, PUT, DELETE)로 표현.
3. **Pagination**:
    - 목록형 데이터를 반환할 때는 메모리 폭발 방지를 위해 반드시 `Pageable` 적용.