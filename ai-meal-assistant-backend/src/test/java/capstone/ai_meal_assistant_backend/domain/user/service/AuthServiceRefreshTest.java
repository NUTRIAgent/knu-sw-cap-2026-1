package capstone.ai_meal_assistant_backend.domain.user.service;

import capstone.ai_meal_assistant_backend.domain.user.dto.AuthResponse;
import capstone.ai_meal_assistant_backend.domain.user.dto.RefreshRequest;
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
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.never;
import static org.mockito.BDDMockito.then;

@ExtendWith(MockitoExtension.class)
class AuthServiceRefreshTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtUtil jwtUtil;

    @Mock
    private LoginAttemptService loginAttemptService;

    @Mock
    private RefreshTokenService refreshTokenService;

    @InjectMocks
    private AuthService authService;

    private RefreshRequest createRequest(String refreshToken) {
        RefreshRequest request = new RefreshRequest();
        ReflectionTestUtils.setField(request, "refreshToken", refreshToken);
        return request;
    }

    @Test
    void 유효한_리프레시_토큰이면_새_토큰을_발급한다() {
        // Given
        String refreshToken = "valid-refresh-token";
        User user = User.builder()
                .email("test@example.com")
                .nickname("닉네임")
                .gender(Gender.MALE)
                .role(Role.USER)
                .build();

        given(jwtUtil.validateToken(refreshToken)).willReturn(true);
        given(jwtUtil.isRefreshToken(refreshToken)).willReturn(true);
        given(jwtUtil.getEmailFromToken(refreshToken)).willReturn("test@example.com");
        given(userRepository.findByEmail("test@example.com")).willReturn(Optional.of(user));
        given(jwtUtil.generateAccessToken("test@example.com")).willReturn("new-access-token");
        given(jwtUtil.generateRefreshToken("test@example.com")).willReturn("new-refresh-token");
        given(refreshTokenService.rotate("test@example.com", refreshToken, "new-refresh-token"))
                .willReturn(true);

        // When
        AuthResponse response = authService.refresh(createRequest(refreshToken));

        // Then — 새 토큰 발급 + 원자적 교체(회전)
        assertThat(response.isSuccess()).isTrue();
        assertThat(response.getData().getAccessToken()).isEqualTo("new-access-token");
        assertThat(response.getData().getRefreshToken()).isEqualTo("new-refresh-token");
        assertThat(response.getData().getUser().getEmail()).isEqualTo("test@example.com");
    }

    @Test
    void 서버에_저장된_토큰과_일치하지_않으면_실패_응답을_반환한다() {
        // Given — 회전으로 무효화됐거나 로그아웃된 구 토큰
        String oldToken = "rotated-old-token";
        User user = User.builder()
                .email("test@example.com")
                .nickname("닉네임")
                .gender(Gender.MALE)
                .role(Role.USER)
                .build();

        given(jwtUtil.validateToken(oldToken)).willReturn(true);
        given(jwtUtil.isRefreshToken(oldToken)).willReturn(true);
        given(jwtUtil.getEmailFromToken(oldToken)).willReturn("test@example.com");
        given(userRepository.findByEmail("test@example.com")).willReturn(Optional.of(user));
        given(jwtUtil.generateAccessToken("test@example.com")).willReturn("new-access-token");
        given(jwtUtil.generateRefreshToken("test@example.com")).willReturn("new-refresh-token");
        given(refreshTokenService.rotate("test@example.com", oldToken, "new-refresh-token"))
                .willReturn(false);

        // When
        AuthResponse response = authService.refresh(createRequest(oldToken));

        // Then — 서명이 유효해도 CAS 교체 실패(저장소 불일치)면 거부
        assertThat(response.isSuccess()).isFalse();
        assertThat(response.getError()).isEqualTo("유효하지 않은 리프레시 토큰입니다");
    }

    @Test
    void access_토큰으로는_refresh할_수_없다() {
        // Given — 서명은 유효하지만 type이 refresh가 아님
        String accessToken = "valid-access-token";
        given(jwtUtil.validateToken(accessToken)).willReturn(true);
        given(jwtUtil.isRefreshToken(accessToken)).willReturn(false);

        // When
        AuthResponse response = authService.refresh(createRequest(accessToken));

        // Then
        assertThat(response.isSuccess()).isFalse();
        assertThat(response.getError()).isEqualTo("유효하지 않은 리프레시 토큰입니다");
        then(refreshTokenService).should(never()).rotate(anyString(), anyString(), anyString());
    }

    @Test
    void access_토큰으로는_로그아웃해도_무효화하지_않는다() {
        // Given — access 토큰의 logout 오용 차단 (응답은 멱등 성공)
        String accessToken = "valid-access-token";
        given(jwtUtil.validateToken(accessToken)).willReturn(true);
        given(jwtUtil.isRefreshToken(accessToken)).willReturn(false);

        // When
        AuthResponse response = authService.logout(createRequest(accessToken));

        // Then
        assertThat(response.isSuccess()).isTrue();
        then(refreshTokenService).should(never()).invalidate(anyString());
    }

    @Test
    void 로그아웃하면_저장된_토큰이_무효화된다() {
        // Given
        String refreshToken = "valid-refresh-token";
        given(jwtUtil.validateToken(refreshToken)).willReturn(true);
        given(jwtUtil.isRefreshToken(refreshToken)).willReturn(true);
        given(jwtUtil.getEmailFromToken(refreshToken)).willReturn("test@example.com");

        // When
        AuthResponse response = authService.logout(createRequest(refreshToken));

        // Then
        assertThat(response.isSuccess()).isTrue();
        then(refreshTokenService).should().invalidate("test@example.com");
    }

    @Test
    void 유효하지_않은_토큰으로_로그아웃해도_성공으로_처리한다() {
        // Given — 멱등: 만료/위조 토큰이어도 클라이언트 로그아웃은 진행돼야 한다
        String invalidToken = "expired-token";
        given(jwtUtil.validateToken(invalidToken)).willReturn(false);

        // When
        AuthResponse response = authService.logout(createRequest(invalidToken));

        // Then
        assertThat(response.isSuccess()).isTrue();
        then(refreshTokenService).should(never()).invalidate(anyString());
    }

    @Test
    void 유효하지_않은_리프레시_토큰이면_실패_응답을_반환한다() {
        // Given
        String refreshToken = "expired-or-tampered-token";
        given(jwtUtil.validateToken(refreshToken)).willReturn(false);

        // When
        AuthResponse response = authService.refresh(createRequest(refreshToken));

        // Then
        assertThat(response.isSuccess()).isFalse();
        assertThat(response.getData()).isNull();
        assertThat(response.getError()).isEqualTo("유효하지 않은 리프레시 토큰입니다");
    }

    @Test
    void 토큰의_사용자가_존재하지_않으면_실패_응답을_반환한다() {
        // Given
        String refreshToken = "valid-refresh-token";
        given(jwtUtil.validateToken(refreshToken)).willReturn(true);
        given(jwtUtil.isRefreshToken(refreshToken)).willReturn(true);
        given(jwtUtil.getEmailFromToken(refreshToken)).willReturn("ghost@example.com");
        given(userRepository.findByEmail("ghost@example.com")).willReturn(Optional.empty());

        // When
        AuthResponse response = authService.refresh(createRequest(refreshToken));

        // Then
        assertThat(response.isSuccess()).isFalse();
        assertThat(response.getData()).isNull();
        assertThat(response.getError()).isEqualTo("존재하지 않는 사용자입니다");
    }
}
