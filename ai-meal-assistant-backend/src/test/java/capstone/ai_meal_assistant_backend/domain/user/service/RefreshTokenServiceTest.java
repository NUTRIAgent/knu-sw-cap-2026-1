package capstone.ai_meal_assistant_backend.domain.user.service;

import capstone.ai_meal_assistant_backend.global.security.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentMatchers;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.RedisConnectionFailureException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.data.redis.core.script.RedisScript;

import java.time.Duration;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;
import static org.mockito.BDDMockito.willThrow;
import static org.mockito.Mockito.lenient;

@ExtendWith(MockitoExtension.class)
class RefreshTokenServiceTest {

    private static final String EMAIL = "test@example.com";
    private static final String KEY = "refresh:token:" + EMAIL;

    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOperations;

    @Mock
    private JwtUtil jwtUtil;

    @InjectMocks
    private RefreshTokenService refreshTokenService;

    @BeforeEach
    void setUp() {
        lenient().when(redisTemplate.opsForValue()).thenReturn(valueOperations);
    }

    @Test
    void 토큰을_저장하면_만료기간과_함께_기록된다() {
        // Given — TTL은 JWT refresh 토큰 유효기간과 동일
        given(jwtUtil.getRefreshTokenValidity()).willReturn(Duration.ofDays(7));

        // When
        refreshTokenService.store(EMAIL, "token-1");

        // Then
        then(valueOperations).should().set(KEY, "token-1", Duration.ofDays(7));
    }

    @Test
    void 저장된_토큰과_일치하면_원자적으로_교체하고_true를_반환한다() {
        // Given — CAS 스크립트가 1(교체 성공)을 반환
        given(jwtUtil.getRefreshTokenValidity()).willReturn(Duration.ofDays(7));
        given(redisTemplate.execute(
                ArgumentMatchers.<RedisScript<Long>>any(),
                eq(List.of(KEY)),
                eq("token-1"), eq("token-2"), anyString()))
                .willReturn(1L);

        // When & Then
        assertThat(refreshTokenService.rotate(EMAIL, "token-1", "token-2")).isTrue();
    }

    @Test
    void 저장된_토큰과_다르면_교체하지_않고_false를_반환한다() {
        // Given — 이미 회전됐거나 로그아웃된 구 토큰 (스크립트가 0 반환)
        given(jwtUtil.getRefreshTokenValidity()).willReturn(Duration.ofDays(7));
        given(redisTemplate.execute(
                ArgumentMatchers.<RedisScript<Long>>any(),
                eq(List.of(KEY)),
                eq("stale-token"), eq("token-2"), anyString()))
                .willReturn(0L);

        // When & Then
        assertThat(refreshTokenService.rotate(EMAIL, "stale-token", "token-2")).isFalse();
    }

    @Test
    void 무효화하면_저장된_토큰이_삭제된다() {
        // When
        refreshTokenService.invalidate(EMAIL);

        // Then
        then(redisTemplate).should().delete(KEY);
    }

    @Test
    void Redis_장애_시_저장을_생략하고_예외를_전파하지_않는다() {
        // Given — fail-open: 토큰 저장 실패가 로그인을 막지 않는다 (미저장 토큰은 refresh에서 거부 → 재로그인)
        given(jwtUtil.getRefreshTokenValidity()).willReturn(Duration.ofDays(7));
        willThrow(new RedisConnectionFailureException("redis down"))
                .given(valueOperations).set(KEY, "token-1", Duration.ofDays(7));

        // When & Then — 예외 없이 종료
        refreshTokenService.store(EMAIL, "token-1");
    }
}
