package capstone.ai_meal_assistant_backend.domain.user.service;

import capstone.ai_meal_assistant_backend.domain.user.dto.AuthResponse;
import capstone.ai_meal_assistant_backend.domain.user.dto.LoginRequest;
import capstone.ai_meal_assistant_backend.domain.user.entity.Gender;
import capstone.ai_meal_assistant_backend.domain.user.entity.Role;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.domain.user.exception.AccountLockedException;
import capstone.ai_meal_assistant_backend.domain.user.repository.UserRepository;
import capstone.ai_meal_assistant_backend.global.security.JwtUtil;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.RedisConnectionFailureException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.never;
import static org.mockito.BDDMockito.then;
import static org.mockito.BDDMockito.willThrow;
import static org.mockito.Mockito.lenient;

@ExtendWith(MockitoExtension.class)
class AuthServiceLoginLockTest {

    private static final String EMAIL = "test@example.com";
    private static final String FAIL_KEY = "login:fail:" + EMAIL;
    private static final String LOCK_KEY = "login:lock:" + EMAIL;

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtUtil jwtUtil;

    @Mock
    private RefreshTokenService refreshTokenService;

    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOperations;

    private AuthService authService;

    @BeforeEach
    void setUp() {
        lenient().when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        // LoginAttemptService는 실제 구현 + Redis mock으로 조립해 잠금 정책 흐름을 검증
        LoginAttemptService loginAttemptService = new LoginAttemptService(redisTemplate);
        authService = new AuthService(userRepository, passwordEncoder, jwtUtil, loginAttemptService, refreshTokenService);
    }

    private LoginRequest createRequest(String email, String password) {
        LoginRequest request = new LoginRequest();
        ReflectionTestUtils.setField(request, "email", email);
        ReflectionTestUtils.setField(request, "password", password);
        return request;
    }

    private User createUser() {
        return User.builder()
                .id(1L)
                .email(EMAIL)
                .password("encoded-password")
                .nickname("닉네임")
                .gender(Gender.MALE)
                .role(Role.USER)
                .build();
    }

    @Test
    void 잠금_상태에서_로그인하면_AccountLockedException이_발생한다() {
        // Given — 잠금 키 TTL이 남아 있음
        given(userRepository.findByEmail(EMAIL)).willReturn(Optional.of(createUser()));
        given(redisTemplate.getExpire(LOCK_KEY)).willReturn(300L);

        // When & Then — 잠금 중에는 비밀번호 검증 없이 차단된다 (이미 잠긴 상태이므로 lockedNow=false)
        assertThatThrownBy(() -> authService.login(createRequest(EMAIL, "password1!")))
                .isInstanceOf(AccountLockedException.class)
                .matches(e -> !((AccountLockedException) e).isLockedNow());
        then(passwordEncoder).should(never()).matches(anyString(), anyString());
    }

    @Test
    void 비밀번호_5회_실패하면_계정이_잠기고_AccountLockedException이_발생한다() {
        // Given — 잠겨 있지 않은 상태에서 INCR이 1→5로 누적
        given(userRepository.findByEmail(EMAIL)).willReturn(Optional.of(createUser()));
        given(redisTemplate.getExpire(LOCK_KEY)).willReturn(-2L);
        given(passwordEncoder.matches(anyString(), anyString())).willReturn(false);
        given(valueOperations.increment(FAIL_KEY)).willReturn(1L, 2L, 3L, 4L, 5L);

        // When — 4회까지는 동일한 실패 응답
        for (int i = 0; i < LoginAttemptService.MAX_FAILED_ATTEMPTS - 1; i++) {
            AuthResponse response = authService.login(createRequest(EMAIL, "wrong-password1!"));
            assertThat(response.isSuccess()).isFalse();
            assertThat(response.getError()).isEqualTo("이메일 또는 비밀번호가 일치하지 않습니다");
        }

        // Then — 5번째 실패에서 잠금 키 설정 및 예외 발생 (이번 실패로 잠겼으므로 lockedNow=true)
        assertThatThrownBy(() -> authService.login(createRequest(EMAIL, "wrong-password1!")))
                .isInstanceOf(AccountLockedException.class)
                .matches(e -> ((AccountLockedException) e).isLockedNow());
        then(valueOperations).should()
                .set(LOCK_KEY, "1", LoginAttemptService.LOCK_DURATION);
    }

    @Test
    void 로그인_성공하면_실패_기록이_정리된다() {
        // Given
        given(userRepository.findByEmail(EMAIL)).willReturn(Optional.of(createUser()));
        given(redisTemplate.getExpire(LOCK_KEY)).willReturn(-2L);
        given(passwordEncoder.matches(anyString(), anyString())).willReturn(true);
        given(jwtUtil.generateAccessToken(EMAIL)).willReturn("access-token");
        given(jwtUtil.generateRefreshToken(EMAIL)).willReturn("refresh-token");

        // When
        AuthResponse response = authService.login(createRequest(EMAIL, "password1!"));

        // Then — 실패 카운터/잠금 키 모두 정리
        assertThat(response.isSuccess()).isTrue();
        then(redisTemplate).should().delete(FAIL_KEY);
        then(redisTemplate).should().delete(LOCK_KEY);
    }

    @Test
    void Redis_장애_시에도_로그인이_가능하다() {
        // Given — fail-open: 잠금 검사/기록이 모두 Redis 예외를 던지는 전면 장애 상황
        given(userRepository.findByEmail(EMAIL)).willReturn(Optional.of(createUser()));
        given(redisTemplate.getExpire(LOCK_KEY))
                .willThrow(new RedisConnectionFailureException("redis down"));
        willThrow(new RedisConnectionFailureException("redis down"))
                .given(redisTemplate).delete(FAIL_KEY);
        given(passwordEncoder.matches(anyString(), anyString())).willReturn(true);
        given(jwtUtil.generateAccessToken(EMAIL)).willReturn("access-token");
        given(jwtUtil.generateRefreshToken(EMAIL)).willReturn("refresh-token");

        // When
        AuthResponse response = authService.login(createRequest(EMAIL, "password1!"));

        // Then — 가용성 우선: 로그인은 성공한다
        assertThat(response.isSuccess()).isTrue();
    }

    @Test
    void 비밀번호가_틀리면_존재하지_않는_이메일과_동일한_메시지를_반환한다() {
        // Given — 이메일 존재 여부가 노출되지 않아야 한다
        given(userRepository.findByEmail(EMAIL)).willReturn(Optional.of(createUser()));
        given(userRepository.findByEmail("ghost@example.com")).willReturn(Optional.empty());
        given(redisTemplate.getExpire(LOCK_KEY)).willReturn(-2L);
        given(passwordEncoder.matches(anyString(), anyString())).willReturn(false);
        given(valueOperations.increment(FAIL_KEY)).willReturn(1L);

        // When
        AuthResponse wrongPassword = authService.login(createRequest(EMAIL, "wrong-password1!"));
        AuthResponse unknownEmail = authService.login(createRequest("ghost@example.com", "wrong-password1!"));

        // Then
        assertThat(wrongPassword.isSuccess()).isFalse();
        assertThat(unknownEmail.isSuccess()).isFalse();
        assertThat(wrongPassword.getError()).isEqualTo(unknownEmail.getError());
    }
}
