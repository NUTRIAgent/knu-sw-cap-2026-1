package capstone.ai_meal_assistant_backend.domain.user.service;

import capstone.ai_meal_assistant_backend.domain.history.repository.RecommendationLogRepository;
import capstone.ai_meal_assistant_backend.domain.ingredient.repository.UserFavoriteIngredientRepository;
import capstone.ai_meal_assistant_backend.domain.menu.repository.UserAllergyRepository;
import capstone.ai_meal_assistant_backend.domain.notification.repository.UserDeviceTokenRepository;
import capstone.ai_meal_assistant_backend.domain.notification.repository.UserIngredientAlertRepository;
import capstone.ai_meal_assistant_backend.domain.user.entity.Gender;
import capstone.ai_meal_assistant_backend.domain.user.entity.Role;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.domain.user.repository.UserRepository;
import capstone.ai_meal_assistant_backend.global.dto.ApiResponse;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.RedisConnectionFailureException;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.never;
import static org.mockito.BDDMockito.then;
import static org.mockito.BDDMockito.willThrow;

@ExtendWith(MockitoExtension.class)
class AccountDeletionServiceTest {

    private static final String EMAIL = "test@example.com";

    @Mock
    private UserRepository userRepository;

    @Mock
    private UserAllergyRepository userAllergyRepository;

    @Mock
    private UserFavoriteIngredientRepository userFavoriteIngredientRepository;

    @Mock
    private UserDeviceTokenRepository userDeviceTokenRepository;

    @Mock
    private UserIngredientAlertRepository userIngredientAlertRepository;

    @Mock
    private RecommendationLogRepository recommendationLogRepository;

    @Mock
    private RefreshTokenService refreshTokenService;

    @InjectMocks
    private AccountDeletionService accountDeletionService;

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
    void 탈퇴하면_연관_데이터와_계정이_모두_삭제되고_토큰이_무효화된다() {
        // Given
        User user = createUser();
        given(userRepository.findByEmail(EMAIL)).willReturn(Optional.of(user));

        // When
        ApiResponse<Void> response = accountDeletionService.deleteAccount(EMAIL);

        // Then — cascade 미설정 자식 데이터 전부 정리 후 계정 삭제 + 세션 무효화
        assertThat(response.isSuccess()).isTrue();
        then(userAllergyRepository).should().deleteByUser(user);
        then(userFavoriteIngredientRepository).should().deleteByUser(user);
        then(userDeviceTokenRepository).should().deleteByUser(user);
        then(userIngredientAlertRepository).should().deleteByUser(user);
        then(recommendationLogRepository).should().deleteByUser(user);
        then(userRepository).should().delete(user);
        then(refreshTokenService).should().invalidate(EMAIL);
    }

    @Test
    void 가입되지_않은_이메일이면_실패하고_아무것도_삭제하지_않는다() {
        // Given
        given(userRepository.findByEmail(EMAIL)).willReturn(Optional.empty());

        // When
        ApiResponse<Void> response = accountDeletionService.deleteAccount(EMAIL);

        // Then
        assertThat(response.isSuccess()).isFalse();
        assertThat(response.getError()).isEqualTo("사용자를 찾을 수 없습니다");
        then(userRepository).should(never()).delete(any(User.class));
        then(refreshTokenService).should(never()).invalidate(EMAIL);
    }

    @Test
    void Redis_장애여도_탈퇴는_완료된다() {
        // Given — 토큰 무효화 실패는 탈퇴를 막지 않는다 (TTL로 결국 만료)
        User user = createUser();
        given(userRepository.findByEmail(EMAIL)).willReturn(Optional.of(user));
        willThrow(new RedisConnectionFailureException("redis down"))
                .given(refreshTokenService).invalidate(EMAIL);

        // When
        ApiResponse<Void> response = accountDeletionService.deleteAccount(EMAIL);

        // Then
        assertThat(response.isSuccess()).isTrue();
        then(userRepository).should().delete(user);
    }
}
