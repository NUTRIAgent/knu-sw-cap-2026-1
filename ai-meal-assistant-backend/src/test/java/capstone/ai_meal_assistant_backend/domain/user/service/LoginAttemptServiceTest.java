package capstone.ai_meal_assistant_backend.domain.user.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.RedisConnectionFailureException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.never;
import static org.mockito.BDDMockito.then;
import static org.mockito.Mockito.lenient;

@ExtendWith(MockitoExtension.class)
class LoginAttemptServiceTest {

    private static final String EMAIL = "test@example.com";
    private static final String FAIL_KEY = "login:fail:" + EMAIL;
    private static final String LOCK_KEY = "login:lock:" + EMAIL;

    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOperations;

    @InjectMocks
    private LoginAttemptService loginAttemptService;

    @BeforeEach
    void setUp() {
        lenient().when(redisTemplate.opsForValue()).thenReturn(valueOperations);
    }

    @Test
    void 실패가_5회_누적되면_계정이_잠긴다() {
        // Given — INCR 결과가 최대치 도달
        given(valueOperations.increment(FAIL_KEY))
                .willReturn((long) LoginAttemptService.MAX_FAILED_ATTEMPTS);

        // When
        boolean locked = loginAttemptService.onLoginFailure(EMAIL);

        // Then — 잠금 키 TTL 설정 + 실패 카운터 정리 (잠금 만료 후 1부터 다시 카운트)
        assertThat(locked).isTrue();
        then(valueOperations).should()
                .set(LOCK_KEY, "1", LoginAttemptService.LOCK_DURATION);
        then(redisTemplate).should().delete(FAIL_KEY);
    }

    @Test
    void 실패가_5회_미만이면_잠기지_않는다() {
        // Given
        given(valueOperations.increment(FAIL_KEY))
                .willReturn((long) LoginAttemptService.MAX_FAILED_ATTEMPTS - 1);

        // When
        boolean locked = loginAttemptService.onLoginFailure(EMAIL);

        // Then — 실패 윈도우 TTL만 갱신, 잠금 키는 만들지 않는다
        assertThat(locked).isFalse();
        then(redisTemplate).should().expire(FAIL_KEY, LoginAttemptService.FAIL_COUNT_WINDOW);
        then(valueOperations).should(never())
                .set(LOCK_KEY, "1", LoginAttemptService.LOCK_DURATION);
    }

    @Test
    void 잠긴_계정은_잠금_키의_TTL이_남은_시간이다() {
        // Given
        given(redisTemplate.getExpire(LOCK_KEY)).willReturn(120L);

        // When & Then
        assertThat(loginAttemptService.getRemainingLockSeconds(EMAIL)).isEqualTo(120L);
    }

    @Test
    void 잠겨_있지_않으면_남은_잠금_시간이_0이다() {
        // Given — 키가 없으면 -2 반환 (null 포함 0으로 처리)
        given(redisTemplate.getExpire(LOCK_KEY)).willReturn(-2L);

        // When & Then
        assertThat(loginAttemptService.getRemainingLockSeconds(EMAIL)).isZero();
    }

    @Test
    void 로그인_성공하면_실패_기록과_잠금이_정리된다() {
        // When
        loginAttemptService.onLoginSuccess(EMAIL);

        // Then
        then(redisTemplate).should().delete(FAIL_KEY);
        then(redisTemplate).should().delete(LOCK_KEY);
    }

    @Test
    void Redis_장애_시_잠금_검사를_생략하고_0을_반환한다() {
        // Given — fail-open: 가용성 우선
        given(redisTemplate.getExpire(LOCK_KEY))
                .willThrow(new RedisConnectionFailureException("redis down"));

        // When & Then
        assertThat(loginAttemptService.getRemainingLockSeconds(EMAIL)).isZero();
    }

    @Test
    void Redis_장애_시_실패_기록을_생략하고_잠그지_않는다() {
        // Given
        given(valueOperations.increment(FAIL_KEY))
                .willThrow(new RedisConnectionFailureException("redis down"));

        // When & Then — 예외를 전파하지 않고 false 반환 (로그인 흐름 유지)
        assertThat(loginAttemptService.onLoginFailure(EMAIL)).isFalse();
    }

    @Test
    void Redis_장애_시_성공_처리도_예외를_전파하지_않는다() {
        // Given
        given(redisTemplate.delete(FAIL_KEY))
                .willThrow(new RedisConnectionFailureException("redis down"));

        // When & Then — 예외 없이 종료
        loginAttemptService.onLoginSuccess(EMAIL);
    }

    // 정책 상수 고정 (변경 시 테스트도 함께 갱신)
    @Test
    void 잠금_정책_상수를_확인한다() {
        assertThat(LoginAttemptService.MAX_FAILED_ATTEMPTS).isEqualTo(5);
        assertThat(LoginAttemptService.LOCK_DURATION).isEqualTo(Duration.ofMinutes(5));
        assertThat(LoginAttemptService.FAIL_COUNT_WINDOW).isEqualTo(Duration.ofMinutes(5));
    }
}
