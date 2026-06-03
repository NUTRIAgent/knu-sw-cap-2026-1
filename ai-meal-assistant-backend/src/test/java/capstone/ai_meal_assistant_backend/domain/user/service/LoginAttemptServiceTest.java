package capstone.ai_meal_assistant_backend.domain.user.service;

import capstone.ai_meal_assistant_backend.domain.user.entity.Gender;
import capstone.ai_meal_assistant_backend.domain.user.entity.Role;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.domain.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.never;
import static org.mockito.BDDMockito.then;

@ExtendWith(MockitoExtension.class)
class LoginAttemptServiceTest {

    private static final long USER_ID = 1L;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private LoginAttemptService loginAttemptService;

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
    void 실패가_5회_누적되면_계정이_잠긴다() {
        // Given — 이번 실패로 누적 횟수가 최대치에 도달
        User user = createUser();
        given(userRepository.findFailedLoginCountById(USER_ID))
                .willReturn(LoginAttemptService.MAX_FAILED_ATTEMPTS);

        // When
        boolean locked = loginAttemptService.onLoginFailure(user);

        // Then — 원자적 증가 후 잠금 처리
        assertThat(locked).isTrue();
        then(userRepository).should().incrementFailedLoginCount(USER_ID);
        then(userRepository).should().lockUntil(eq(USER_ID), any(LocalDateTime.class));
    }

    @Test
    void 실패가_5회_미만이면_잠기지_않는다() {
        // Given
        User user = createUser();
        given(userRepository.findFailedLoginCountById(USER_ID))
                .willReturn(LoginAttemptService.MAX_FAILED_ATTEMPTS - 1);

        // When
        boolean locked = loginAttemptService.onLoginFailure(user);

        // Then
        assertThat(locked).isFalse();
        then(userRepository).should().incrementFailedLoginCount(USER_ID);
        then(userRepository).should(never()).lockUntil(eq(USER_ID), any(LocalDateTime.class));
    }

    @Test
    void 잠금이_만료되면_남은_잠금_시간이_0이다() {
        // Given
        User user = createUser(LoginAttemptService.MAX_FAILED_ATTEMPTS,
                LocalDateTime.now().minusSeconds(1));

        // When
        long remaining = loginAttemptService.getRemainingLockSeconds(user);

        // Then
        assertThat(remaining).isZero();
    }

    @Test
    void 잠금_만료_후_실패하면_횟수를_초기화하고_다시_카운트한다() {
        // Given — 잠금 시간이 지난 상태에서 다시 실패
        User user = createUser(LoginAttemptService.MAX_FAILED_ATTEMPTS,
                LocalDateTime.now().minusSeconds(1));
        given(userRepository.findFailedLoginCountById(USER_ID)).willReturn(1);

        // When
        boolean locked = loginAttemptService.onLoginFailure(user);

        // Then — 초기화 후 1부터 다시 시작하므로 잠기지 않는다
        assertThat(locked).isFalse();
        then(userRepository).should().resetLoginFailure(USER_ID);
        then(userRepository).should().incrementFailedLoginCount(USER_ID);
    }

    @Test
    void 로그인_성공하면_실패_기록이_초기화된다() {
        // Given — 실패가 누적된 사용자
        User user = createUser(2, null);

        // When
        loginAttemptService.onLoginSuccess(user);

        // Then
        then(userRepository).should().resetLoginFailure(USER_ID);
    }

    @Test
    void 실패_기록이_없으면_로그인_성공_시_초기화하지_않는다() {
        // Given — 불필요한 UPDATE 쿼리 방지
        User user = createUser();

        // When
        loginAttemptService.onLoginSuccess(user);

        // Then
        then(userRepository).should(never()).resetLoginFailure(USER_ID);
    }
}
