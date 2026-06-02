package capstone.ai_meal_assistant_backend.domain.user.service;

import capstone.ai_meal_assistant_backend.domain.user.dto.AuthResponse;
import capstone.ai_meal_assistant_backend.domain.user.dto.LoginRequest;
import capstone.ai_meal_assistant_backend.domain.user.dto.SignupRequest;
import capstone.ai_meal_assistant_backend.domain.user.entity.Gender;
import capstone.ai_meal_assistant_backend.domain.user.entity.Role;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.domain.user.repository.UserRepository;
import capstone.ai_meal_assistant_backend.global.security.JwtUtil;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.then;

@ExtendWith(MockitoExtension.class)
class AuthServiceSignupTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtUtil jwtUtil;

    @InjectMocks
    private AuthService authService;

    private SignupRequest createSignupRequest(String email) {
        SignupRequest request = new SignupRequest();
        ReflectionTestUtils.setField(request, "email", email);
        ReflectionTestUtils.setField(request, "password", "abcd1234!");
        ReflectionTestUtils.setField(request, "nickname", "닉네임");
        ReflectionTestUtils.setField(request, "phoneNumber", "01012345678");
        ReflectionTestUtils.setField(request, "gender", Gender.MALE);
        return request;
    }

    private LoginRequest createLoginRequest(String email, String password) {
        LoginRequest request = new LoginRequest();
        ReflectionTestUtils.setField(request, "email", email);
        ReflectionTestUtils.setField(request, "password", password);
        return request;
    }

    @Test
    void 가입_시_이메일이_소문자로_정규화되어_저장된다() {
        // Given
        given(userRepository.existsByEmail("user@example.com")).willReturn(false);
        given(userRepository.existsByNickname("닉네임")).willReturn(false);
        given(passwordEncoder.encode(anyString())).willReturn("encoded-password");
        given(jwtUtil.generateAccessToken("user@example.com")).willReturn("access-token");
        given(jwtUtil.generateRefreshToken("user@example.com")).willReturn("refresh-token");

        // When
        AuthResponse response = authService.signup(createSignupRequest("  User@Example.COM  "));

        // Then
        assertThat(response.isSuccess()).isTrue();
        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        then(userRepository).should().saveAndFlush(userCaptor.capture());
        assertThat(userCaptor.getValue().getEmail()).isEqualTo("user@example.com");
    }

    @Test
    void 가입_응답에_gender가_포함된다() {
        // Given
        given(userRepository.existsByEmail("user@example.com")).willReturn(false);
        given(userRepository.existsByNickname("닉네임")).willReturn(false);
        given(passwordEncoder.encode(anyString())).willReturn("encoded-password");
        given(jwtUtil.generateAccessToken("user@example.com")).willReturn("access-token");
        given(jwtUtil.generateRefreshToken("user@example.com")).willReturn("refresh-token");

        // When
        AuthResponse response = authService.signup(createSignupRequest("user@example.com"));

        // Then — 클라이언트가 로컬 저장에 사용하는 gender가 응답 user에 실린다
        assertThat(response.isSuccess()).isTrue();
        assertThat(response.getData().getUser().getGender()).isEqualTo("MALE");
    }

    @Test
    void 동시_가입으로_unique_제약_위반이_발생하면_중복_안내_메시지를_반환한다() {
        // Given — 사전 중복 체크는 통과했지만 저장 시점에 제약 위반(TOCTOU)
        given(userRepository.existsByEmail("user@example.com")).willReturn(false);
        given(userRepository.existsByNickname("닉네임")).willReturn(false);
        given(passwordEncoder.encode(anyString())).willReturn("encoded-password");
        given(userRepository.saveAndFlush(any(User.class)))
                .willThrow(new DataIntegrityViolationException("unique constraint violation"));

        // When
        AuthResponse response = authService.signup(createSignupRequest("user@example.com"));

        // Then
        assertThat(response.isSuccess()).isFalse();
        assertThat(response.getError()).isEqualTo("이미 사용 중인 이메일/닉네임/휴대폰 번호입니다");
    }

    @Test
    void 로그인_시_이메일_대소문자와_공백을_구분하지_않는다() {
        // Given — 소문자로 저장된 계정
        User user = User.builder()
                .email("user@example.com")
                .password("encoded-password")
                .nickname("닉네임")
                .gender(Gender.MALE)
                .role(Role.USER)
                .build();
        given(userRepository.findByEmail("user@example.com")).willReturn(Optional.of(user));
        given(passwordEncoder.matches(anyString(), anyString())).willReturn(true);
        given(jwtUtil.generateAccessToken("user@example.com")).willReturn("access-token");
        given(jwtUtil.generateRefreshToken("user@example.com")).willReturn("refresh-token");

        // When
        AuthResponse response = authService.login(createLoginRequest("  User@Example.COM  ", "abcd1234!"));

        // Then
        assertThat(response.isSuccess()).isTrue();
        assertThat(response.getData().getUser().getEmail()).isEqualTo("user@example.com");
        assertThat(response.getData().getUser().getGender()).isEqualTo("MALE");
    }
}
