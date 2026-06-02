package capstone.ai_meal_assistant_backend.domain.user.service;

import capstone.ai_meal_assistant_backend.domain.user.entity.Gender;
import capstone.ai_meal_assistant_backend.domain.user.entity.Role;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.domain.user.repository.UserRepository;
import capstone.ai_meal_assistant_backend.global.security.JwtUtil;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.BDDMockito.given;

@ExtendWith(MockitoExtension.class)
class AuthServiceFindEmailTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtUtil jwtUtil;

    @InjectMocks
    private AuthService authService;

    @Test
    void 휴대폰_번호로_마스킹된_이메일을_반환한다() {
        // Given
        User user = User.builder()
                .email("mhy@smail.kongju.ac.kr")
                .nickname("닉네임")
                .phoneNumber("01012345678")
                .gender(Gender.MALE)
                .role(Role.USER)
                .build();
        given(userRepository.findByPhoneNumber("01012345678")).willReturn(Optional.of(user));

        // When
        Optional<String> maskedEmail = authService.findMaskedEmailByPhoneNumber("01012345678");

        // Then
        assertThat(maskedEmail).contains("mh***@smail.kongju.ac.kr");
    }

    @Test
    void 가입되지_않은_휴대폰_번호면_빈_값을_반환한다() {
        // Given
        given(userRepository.findByPhoneNumber("01099999999")).willReturn(Optional.empty());

        // When
        Optional<String> maskedEmail = authService.findMaskedEmailByPhoneNumber("01099999999");

        // Then
        assertThat(maskedEmail).isEmpty();
    }

    @Test
    void 로컬_파트가_2자_이하인_이메일은_첫_글자만_남기고_마스킹한다() {
        // Given & When
        String masked = AuthService.maskEmail("ab@example.com");

        // Then
        assertThat(masked).isEqualTo("a***@example.com");
    }
}
