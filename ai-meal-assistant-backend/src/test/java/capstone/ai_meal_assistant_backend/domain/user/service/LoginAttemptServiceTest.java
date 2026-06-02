package capstone.ai_meal_assistant_backend.domain.user.service;

import capstone.ai_meal_assistant_backend.domain.user.entity.Gender;
import capstone.ai_meal_assistant_backend.domain.user.entity.Role;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

class LoginAttemptServiceTest {

    private final LoginAttemptService loginAttemptService = new LoginAttemptService();

    private User createUser() {
        return User.builder()
                .email("test@example.com")
                .password("encoded-password")
                .nickname("닉네임")
                .gender(Gender.MALE)
                .role(Role.USER)
                .build();
    }

    @Test
    void 실패가_5회_누적되면_계정이_잠긴다() {
        // Given
        User user = createUser();

        // When
        boolean locked = false;
        for (int i = 0; i < LoginAttemptService.MAX_FAILED_ATTEMPTS; i++) {
            locked = loginAttemptService.onLoginFailure(user);
        }

        // Then
        assertThat(locked).isTrue();
        assertThat(user.getFailedLoginCount()).isEqualTo(LoginAttemptService.MAX_FAILED_ATTEMPTS);
        assertThat(user.getLockedUntil()).isNotNull();
        assertThat(loginAttemptService.getRemainingLockSeconds(user)).isPositive();
    }

    @Test
    void 실패가_5회_미만이면_잠기지_않는다() {
        // Given
        User user = createUser();

        // When
        boolean locked = false;
        for (int i = 0; i < LoginAttemptService.MAX_FAILED_ATTEMPTS - 1; i++) {
            locked = loginAttemptService.onLoginFailure(user);
        }

        // Then
        assertThat(locked).isFalse();
        assertThat(user.getLockedUntil()).isNull();
        assertThat(loginAttemptService.getRemainingLockSeconds(user)).isZero();
    }

    @Test
    void 잠금이_만료되면_남은_잠금_시간이_0이다() {
        // Given
        User user = createUser();
        user.lockUntil(LocalDateTime.now().minusSeconds(1));

        // When
        long remaining = loginAttemptService.getRemainingLockSeconds(user);

        // Then
        assertThat(remaining).isZero();
    }

    @Test
    void 잠금_만료_후_실패하면_횟수가_1부터_다시_시작한다() {
        // Given — 5회 실패로 잠긴 뒤 잠금 시간이 지난 상태
        User user = createUser();
        for (int i = 0; i < LoginAttemptService.MAX_FAILED_ATTEMPTS; i++) {
            loginAttemptService.onLoginFailure(user);
        }
        user.lockUntil(LocalDateTime.now().minusSeconds(1));

        // When
        boolean locked = loginAttemptService.onLoginFailure(user);

        // Then
        assertThat(locked).isFalse();
        assertThat(user.getFailedLoginCount()).isEqualTo(1);
        assertThat(user.getLockedUntil()).isNull();
    }

    @Test
    void 로그인_성공하면_실패_기록이_초기화된다() {
        // Given
        User user = createUser();
        loginAttemptService.onLoginFailure(user);
        loginAttemptService.onLoginFailure(user);

        // When
        loginAttemptService.onLoginSuccess(user);

        // Then
        assertThat(user.getFailedLoginCount()).isZero();
        assertThat(user.getLockedUntil()).isNull();
    }
}
