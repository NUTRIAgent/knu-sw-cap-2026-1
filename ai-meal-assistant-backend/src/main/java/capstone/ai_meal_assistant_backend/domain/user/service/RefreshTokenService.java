package capstone.ai_meal_assistant_backend.domain.user.service;

import capstone.ai_meal_assistant_backend.global.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.RedisScript;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Refresh token 서버 측 저장소 (Redis).
 * 발급한 최신 refresh token만 유효하게 유지해 진짜 회전(rotation)과
 * 로그아웃 시 즉시 무효화를 가능하게 한다.
 * 이메일당 토큰 1개만 저장하는 단일 세션 정책 — 새 로그인/회전 시 이전 토큰은 즉시 무효.
 */
@Service
@RequiredArgsConstructor
public class RefreshTokenService {

    private static final String KEY_PREFIX = "refresh:token:";

    // 비교+교체(CAS)를 단일 스크립트로 원자 처리 — 같은 구 토큰으로 동시 refresh가 들어와도 한쪽만 성공
    private static final RedisScript<Long> ROTATE_SCRIPT = RedisScript.of(
            "if redis.call('GET', KEYS[1]) == ARGV[1] then "
                    + "redis.call('SET', KEYS[1], ARGV[2], 'PX', ARGV[3]) return 1 "
                    + "else return 0 end",
            Long.class);

    private final StringRedisTemplate redisTemplate;
    private final JwtUtil jwtUtil;

    // 발급한 refresh token 저장 — 기존 토큰은 덮어써서 즉시 무효화 (TTL은 토큰 만료와 동일)
    public void store(String email, String refreshToken) {
        redisTemplate.opsForValue()
                .set(KEY_PREFIX + email, refreshToken, jwtUtil.getRefreshTokenValidity());
    }

    // 저장된 토큰이 oldToken과 일치할 때만 newToken으로 원자적 교체. 교체 성공 여부를 반환
    public boolean rotate(String email, String oldToken, String newToken) {
        Long result = redisTemplate.execute(
                ROTATE_SCRIPT,
                List.of(KEY_PREFIX + email),
                oldToken, newToken, String.valueOf(jwtUtil.getRefreshTokenValidity().toMillis()));
        return Long.valueOf(1L).equals(result);
    }

    // 로그아웃 — 저장된 토큰 삭제로 이후 refresh 불가 처리
    public void invalidate(String email) {
        redisTemplate.delete(KEY_PREFIX + email);
    }
}
