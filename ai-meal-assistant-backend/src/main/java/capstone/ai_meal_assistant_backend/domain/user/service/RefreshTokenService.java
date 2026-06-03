package capstone.ai_meal_assistant_backend.domain.user.service;

import capstone.ai_meal_assistant_backend.global.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

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

    private final StringRedisTemplate redisTemplate;
    private final JwtUtil jwtUtil;

    // 발급한 refresh token 저장 — 기존 토큰은 덮어써서 즉시 무효화 (TTL은 토큰 만료와 동일)
    public void store(String email, String refreshToken) {
        redisTemplate.opsForValue()
                .set(KEY_PREFIX + email, refreshToken, jwtUtil.getRefreshTokenValidity());
    }

    // 제시된 토큰이 서버에 저장된 최신 토큰과 일치하는지 확인
    public boolean matches(String email, String refreshToken) {
        String saved = redisTemplate.opsForValue().get(KEY_PREFIX + email);
        return saved != null && saved.equals(refreshToken);
    }

    // 로그아웃 — 저장된 토큰 삭제로 이후 refresh 불가 처리
    public void invalidate(String email) {
        redisTemplate.delete(KEY_PREFIX + email);
    }
}
