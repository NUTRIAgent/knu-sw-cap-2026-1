package capstone.ai_meal_assistant_backend.domain.user.service;

import capstone.ai_meal_assistant_backend.global.security.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;
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
    void 저장된_토큰과_일치하면_true를_반환한다() {
        // Given
        given(valueOperations.get(KEY)).willReturn("token-1");

        // When & Then
        assertThat(refreshTokenService.matches(EMAIL, "token-1")).isTrue();
    }

    @Test
    void 저장된_토큰과_다르거나_없으면_false를_반환한다() {
        // Given — 회전으로 교체된 구 토큰 또는 로그아웃 후
        given(valueOperations.get(KEY)).willReturn("token-2");

        // When & Then
        assertThat(refreshTokenService.matches(EMAIL, "token-1")).isFalse();

        // Given — 저장된 토큰 자체가 없는 경우
        given(valueOperations.get(KEY)).willReturn(null);
        assertThat(refreshTokenService.matches(EMAIL, "token-1")).isFalse();
    }

    @Test
    void 무효화하면_저장된_토큰이_삭제된다() {
        // When
        refreshTokenService.invalidate(EMAIL);

        // Then
        then(redisTemplate).should().delete(KEY);
    }
}
