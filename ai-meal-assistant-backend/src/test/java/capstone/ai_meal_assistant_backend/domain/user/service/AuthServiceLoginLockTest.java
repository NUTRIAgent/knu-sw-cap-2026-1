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
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.never;
import static org.mockito.BDDMockito.then;

@ExtendWith(MockitoExtension.class)
class AuthServiceLoginLockTest {

    private static final long USER_ID = 1L;

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtUtil jwtUtil;

    @Mock
    private RefreshTokenService refreshTokenService;

    private AuthService authService;

    @BeforeEach
    void setUp() {
        // LoginAttemptService가 UserRepository를 필요로 하므로 직접 조립
        LoginAttemptService loginAttemptService = new LoginAttemptService(userRepository);
        authService = new AuthService(userRepository, passwordEncoder, jwtUtil, loginAttemptService, refreshTokenService);
    }

    private LoginRequest createRequest(String email, String password) {
        LoginRequest request = new LoginRequest();
        ReflectionTestUtils.setField(request, "email", email);
        ReflectionTestUtils.setField(request, "password", password);
        return request;
    }

    private User createUser() {
        return createUser(0, null);
    }

    private User createUser(int failedLoginCount, LocalDateTime lockedUntil) {
        return User.builder()
                .id(USER_ID)
                .email("test@example.com")
                .password("encoded-password")
                .nickname("닉네임")
                .gender(Gender.MALE)
                .role(Role.USER)
                .failedLoginCount(failedLoginCount)
                .lockedUntil(lockedUntil)
                .build();
    }

    @Test
    void 잠금_상태에서_로그인하면_AccountLockedException이_발생한다() {
        // Given
        User user = createUser(LoginAttemptService.MAX_FAILED_ATTEMPTS,
                LocalDateTime.now().plusMinutes(5));
        given(userRepository.findByEmail("test@example.com")).willReturn(Optional.of(user));

        // When & Then — 잠금 중에는 비밀번호 검증 없이 차단된다 (이미 잠긴 상태이므로 lockedNow=false)
        assertThatThrownBy(() -> authService.login(createRequest("test@example.com", "password1!")))
                .isInstanceOf(AccountLockedException.class)
                .matches(e -> !((AccountLockedException) e).isLockedNow());
        then(passwordEncoder).should(never()).matches(anyString(), anyString());
    }

    @Test
    void 비밀번호_5회_실패하면_계정이_잠기고_AccountLockedException이_발생한다() {
        // Given
        User user = createUser();
        given(userRepository.findByEmail("test@example.com")).willReturn(Optional.of(user));
        given(passwordEncoder.matches(anyString(), anyString())).willReturn(false);
        given(userRepository.findFailedLoginCountById(USER_ID)).willReturn(1, 2, 3, 4, 5);

        // When — 4회까지는 동일한 실패 응답
        for (int i = 0; i < LoginAttemptService.MAX_FAILED_ATTEMPTS - 1; i++) {
            AuthResponse response = authService.login(createRequest("test@example.com", "wrong-password1!"));
            assertThat(response.isSuccess()).isFalse();
            assertThat(response.getError()).isEqualTo("이메일 또는 비밀번호가 일치하지 않습니다");
        }

        // Then — 5번째 실패에서 잠금 처리 및 예외 발생 (이번 실패로 잠겼으므로 lockedNow=true)
        assertThatThrownBy(() -> authService.login(createRequest("test@example.com", "wrong-password1!")))
                .isInstanceOf(AccountLockedException.class)
                .matches(e -> ((AccountLockedException) e).isLockedNow());
        then(userRepository).should().lockUntil(eq(USER_ID), any(LocalDateTime.class));
    }

    @Test
    void 로그인_성공하면_실패_횟수가_초기화된다() {
        // Given — 2회 실패가 누적된 사용자
        User user = createUser(2, null);
        given(userRepository.findByEmail("test@example.com")).willReturn(Optional.of(user));
        given(passwordEncoder.matches(anyString(), anyString())).willReturn(true);
        given(jwtUtil.generateAccessToken("test@example.com")).willReturn("access-token");
        given(jwtUtil.generateRefreshToken("test@example.com")).willReturn("refresh-token");

        // When
        AuthResponse response = authService.login(createRequest("test@example.com", "password1!"));

        // Then
        assertThat(response.isSuccess()).isTrue();
        then(userRepository).should().resetLoginFailure(USER_ID);
    }

    @Test
    void 비밀번호가_틀리면_존재하지_않는_이메일과_동일한_메시지를_반환한다() {
        // Given — 이메일 존재 여부가 노출되지 않아야 한다
        User user = createUser();
        given(userRepository.findByEmail("test@example.com")).willReturn(Optional.of(user));
        given(userRepository.findByEmail("ghost@example.com")).willReturn(Optional.empty());
        given(passwordEncoder.matches(anyString(), anyString())).willReturn(false);
        given(userRepository.findFailedLoginCountById(USER_ID)).willReturn(1);

        // When
        AuthResponse wrongPassword = authService.login(createRequest("test@example.com", "wrong-password1!"));
        AuthResponse unknownEmail = authService.login(createRequest("ghost@example.com", "wrong-password1!"));

        // Then
        assertThat(wrongPassword.isSuccess()).isFalse();
        assertThat(unknownEmail.isSuccess()).isFalse();
        assertThat(wrongPassword.getError()).isEqualTo(unknownEmail.getError());
    }
}
