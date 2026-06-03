package capstone.ai_meal_assistant_backend.domain.user.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataAccessException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;

/**
 * 로그인 실패 횟수 추적 및 계정 잠금 정책을 담당하는 서비스 (Redis 기반).
 * - 실패 횟수는 INCR로 원자 누적 — 동시 로그인 시도에도 카운트가 누락되지 않는다
 * - 잠금/실패 윈도우는 키 TTL로 자동 만료 — 만료 판정 쿼리가 필요 없다
 * - 브루트포스 트래픽이 메인 DB 쓰기 부하로 이어지지 않는다 (#175 후속, #189)
 *
 * 장애 정책: fail-open — Redis 장애 시 잠금 검사/기록을 건너뛰고 로그인을 허용한다.
 * (가용성 우선. 장애 동안 브루트포스 방어가 일시 정지되는 트레이드오프는 팀 합의됨)
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class LoginAttemptService {

    public static final int MAX_FAILED_ATTEMPTS = 5; // 연속 실패 허용 횟수
    public static final Duration LOCK_DURATION = Duration.ofMinutes(5); // 잠금 유지 시간
    public static final Duration FAIL_COUNT_WINDOW = Duration.ofMinutes(5); // 실패 횟수 집계 윈도우

    private static final String FAIL_KEY_PREFIX = "login:fail:";
    private static final String LOCK_KEY_PREFIX = "login:lock:";

    private final StringRedisTemplate redisTemplate;

    // 남은 잠금 시간(초)을 반환. 잠겨 있지 않으면 0 — 잠금 키의 TTL이 곧 남은 시간
    public long getRemainingLockSeconds(String email) {
        try {
            Long ttl = redisTemplate.getExpire(LOCK_KEY_PREFIX + email);
            return (ttl == null || ttl < 0) ? 0 : ttl;
        } catch (DataAccessException e) {
            log.warn("Redis 장애 — 잠금 검사 생략(fail-open): email={}", email, e);
            return 0;
        }
    }

    // 로그인 실패 처리 — 실패 횟수 원자적 누적(INCR), 최대치 도달 시 잠금. 이번 실패로 잠겼는지 여부를 반환
    public boolean onLoginFailure(String email) {
        try {
            String failKey = FAIL_KEY_PREFIX + email;
            Long failedCount = redisTemplate.opsForValue().increment(failKey);
            redisTemplate.expire(failKey, FAIL_COUNT_WINDOW);

            if (failedCount != null && failedCount >= MAX_FAILED_ATTEMPTS) {
                redisTemplate.opsForValue().set(LOCK_KEY_PREFIX + email, "1", LOCK_DURATION);
                redisTemplate.delete(failKey); // 잠금 만료 후 첫 실패는 1부터 다시 카운트
                return true;
            }
            return false;
        } catch (DataAccessException e) {
            log.warn("Redis 장애 — 실패 횟수 기록 생략(fail-open): email={}", email, e);
            return false;
        }
    }

    // 로그인 성공 처리 — 실패 기록/잠금 키 정리 (DEL은 멱등이라 무조건 호출해도 안전)
    public void onLoginSuccess(String email) {
        try {
            redisTemplate.delete(FAIL_KEY_PREFIX + email);
            redisTemplate.delete(LOCK_KEY_PREFIX + email);
        } catch (DataAccessException e) {
            log.warn("Redis 장애 — 실패 기록 정리 생략(fail-open): email={}", email, e);
        }
    }
}
