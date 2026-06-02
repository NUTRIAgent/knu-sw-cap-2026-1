# users 테이블 — 회원가입 검증 강화 관련 스키마/데이터 마이그레이션 가이드

회원가입 기능 개선(#165, #168)으로 `users` 테이블에 아래 변경이 생겼습니다.
백엔드는 `ddl-auto: update`라 **컬럼 추가/인덱스 생성은 기동 시 자동 반영**되지만,
**기존 데이터가 조건을 만족하지 않으면 기동 실패 또는 무결성 문제**가 발생할 수 있어
기존 레코드가 있는 DB에는 아래 정리를 먼저 수행해야 합니다.

> ⚠️ 운영/공유 DB에 적용하기 전 반드시 백업하세요.
> 로컬 개발 DB(레코드 없음/재생성 가능)는 이 가이드가 필요 없습니다.

## 변경 사항 요약

| 변경 | 기존 데이터 위험 |
|---|---|
| `gender` 컬럼 — `NOT NULL` | 컬럼 추가 시 기존 행이 NULL/빈 값 → enum 매핑 오류 |
| `nickname` — `UNIQUE` 제약 | 중복 닉네임 존재 시 인덱스 생성 실패 |
| 이메일 소문자 정규화(서비스 레이어) | 대소문자만 다른 기존 계정은 로그인 불일치 가능 |

## 1. 사전 점검

```sql
-- gender가 비어 있는 기존 행 확인
SELECT id, email, gender FROM users WHERE gender IS NULL OR gender = '';

-- 중복 닉네임 확인 (unique 인덱스 생성을 막는 행)
SELECT nickname, COUNT(*) AS cnt FROM users
GROUP BY nickname HAVING cnt > 1;

-- 소문자 변환 시 충돌하는 이메일 확인 (있으면 수동 판단 필요)
SELECT LOWER(email) AS normalized, COUNT(*) AS cnt FROM users
GROUP BY normalized HAVING cnt > 1;
```

## 2. 데이터 정리 (점검 결과가 있을 때만)

```sql
-- 2-1. gender 기본값 채우기
--      ⚠️ 실제 값은 알 수 없으므로 임시값입니다. 해당 사용자에게 재설정을 안내하세요.
UPDATE users SET gender = 'MALE' WHERE gender IS NULL OR gender = '';

-- 2-2. 중복 닉네임에 suffix 부여 (id가 가장 작은 행만 원본 유지)
UPDATE users u
JOIN (
    SELECT id, CONCAT(nickname, '_', id) AS new_nickname
    FROM users
    WHERE nickname IN (
        SELECT nickname FROM (
            SELECT nickname FROM users GROUP BY nickname HAVING COUNT(*) > 1
        ) d
    )
    AND id NOT IN (
        SELECT min_id FROM (
            SELECT MIN(id) AS min_id FROM users GROUP BY nickname HAVING COUNT(*) > 1
        ) m
    )
) t ON u.id = t.id
SET u.nickname = t.new_nickname;

-- 2-3. 이메일 소문자 정규화 (1번 점검에서 충돌이 없을 때만 실행)
UPDATE users SET email = LOWER(email) WHERE email <> LOWER(email);
```

## 3. 적용 순서

1. DB 백업
2. 1번 점검 쿼리 실행 → 결과가 모두 0건이면 2번 생략
3. 2번 정리 쿼리 실행 (해당 항목만)
4. 백엔드 기동 → `ddl-auto: update`가 컬럼/인덱스 자동 반영
5. 기동 로그에서 `ALTER TABLE` 오류 없는지 확인

## 롤백

- 컬럼 제거: `ALTER TABLE users DROP COLUMN gender;` (단, 코드도 함께 롤백 필요)
- unique 인덱스 제거: `SHOW INDEX FROM users;`로 인덱스명 확인 후 `ALTER TABLE users DROP INDEX <인덱스명>;`
- 정리 쿼리로 변경된 데이터는 백업에서 복원

## 향후

레코드가 쌓인 뒤에는 Flyway/Liquibase 도입(스키마 버전 관리)을 권장합니다 — 팀 합의 후 별도 이슈로 진행.
