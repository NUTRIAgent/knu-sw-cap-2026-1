package capstone.ai_meal_assistant_backend.domain.user.service;

import capstone.ai_meal_assistant_backend.domain.user.entity.Gender;
import capstone.ai_meal_assistant_backend.domain.user.entity.Role;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.domain.user.repository.UserRepository;
import capstone.ai_meal_assistant_backend.global.dto.ApiResponse;
import capstone.ai_meal_assistant_backend.global.mail.MailService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.Duration;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.never;
import static org.mockito.BDDMockito.then;
import static org.mockito.Mockito.lenient;

@ExtendWith(MockitoExtension.class)
class PasswordResetServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private StringRedisTemplate redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOperations;

    @Mock
    private MailService mailService;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private PasswordResetService passwordResetService;

    private static final String EMAIL = "test@example.com";
    private static final String CODE_KEY = "pwreset:code:" + EMAIL;
    private static final String COOLDOWN_KEY = "pwreset:cooldown:" + EMAIL;
    private static final String ATTEMPT_KEY = "pwreset:attempts:" + EMAIL;

    @BeforeEach
    void setUp() {
        // opsForValue()는 모든 경로에서 쓰이므로 lenient 처리
        lenient().when(redisTemplate.opsForValue()).thenReturn(valueOperations);
    }

    @Test
    void 가입되지_않은_이메일이면_코드를_발송하지_않는다() {
        // Given
        given(userRepository.existsByEmail(EMAIL)).willReturn(false);

        // When
        ApiResponse<Void> response = passwordResetService.sendCode(EMAIL);

        // Then
        assertThat(response.isSuccess()).isFalse();
        assertThat(response.getError()).isEqualTo("가입되지 않은 이메일입니다");
        then(mailService).should(never()).send(anyString(), anyString(), anyString());
    }

    @Test
    void 재발송_제한_시간_내의_요청은_거부된다() {
        // Given — 쿨다운 키가 이미 존재 (setIfAbsent 실패)
        given(userRepository.existsByEmail(EMAIL)).willReturn(true);
        given(valueOperations.setIfAbsent(eq(COOLDOWN_KEY), anyString(), eq(PasswordResetService.RESEND_COOLDOWN)))
                .willReturn(false);

        // When
        ApiResponse<Void> response = passwordResetService.sendCode(EMAIL);

        // Then
        assertThat(response.isSuccess()).isFalse();
        then(mailService).should(never()).send(anyString(), anyString(), anyString());
    }

    @Test
    void 인증코드를_생성해_저장하고_메일로_발송한다() {
        // Given
        given(userRepository.existsByEmail(EMAIL)).willReturn(true);
        given(valueOperations.setIfAbsent(eq(COOLDOWN_KEY), anyString(), eq(PasswordResetService.RESEND_COOLDOWN)))
                .willReturn(true);
        given(mailService.send(eq(EMAIL), anyString(), anyString())).willReturn(true);

        // When
        ApiResponse<Void> response = passwordResetService.sendCode(EMAIL);

        // Then
        assertThat(response.isSuccess()).isTrue();
        then(valueOperations).should()
                .set(eq(CODE_KEY), anyString(), eq(PasswordResetService.CODE_TTL));
        then(mailService).should().send(eq(EMAIL), contains("인증코드"), anyString());
    }

    @Test
    void 메일_발송에_실패하면_실패_응답을_반환한다() {
        // Given
        given(userRepository.existsByEmail(EMAIL)).willReturn(true);
        given(valueOperations.setIfAbsent(eq(COOLDOWN_KEY), anyString(), eq(PasswordResetService.RESEND_COOLDOWN)))
                .willReturn(true);
        given(mailService.send(eq(EMAIL), anyString(), anyString())).willReturn(false);

        // When
        ApiResponse<Void> response = passwordResetService.sendCode(EMAIL);

        // Then
        assertThat(response.isSuccess()).isFalse();
        assertThat(response.getError()).contains("메일 발송에 실패");
    }

    @Test
    void 코드가_일치하면_검증에_성공한다() {
        // Given
        given(valueOperations.get(CODE_KEY)).willReturn("123456");

        // When
        ApiResponse<Void> response = passwordResetService.verifyCode(EMAIL, "123456");

        // Then
        assertThat(response.isSuccess()).isTrue();
    }

    @Test
    void 코드가_다르거나_만료되면_검증에_실패한다() {
        // Given — 만료된 경우 Redis에서 null 반환
        given(valueOperations.get(CODE_KEY)).willReturn(null);

        // When
        ApiResponse<Void> response = passwordResetService.verifyCode(EMAIL, "123456");

        // Then
        assertThat(response.isSuccess()).isFalse();
        assertThat(response.getError()).isEqualTo("인증코드가 일치하지 않거나 만료되었습니다");
    }

    @Test
    void 비밀번호_재설정에_성공하면_비밀번호가_변경되고_코드가_폐기된다() {
        // Given
        User user = User.builder()
                .email(EMAIL)
                .password("old-encoded")
                .nickname("닉네임")
                .gender(Gender.MALE)
                .role(Role.USER)
                .build();
        given(valueOperations.get(CODE_KEY)).willReturn("123456");
        given(userRepository.findByEmail(EMAIL)).willReturn(Optional.of(user));
        given(passwordEncoder.encode("newPass1!")).willReturn("new-encoded");

        // When
        ApiResponse<Void> response = passwordResetService.resetPassword(EMAIL, "123456", "newPass1!");

        // Then
        assertThat(response.isSuccess()).isTrue();
        assertThat(user.getPassword()).isEqualTo("new-encoded");
        then(redisTemplate).should().delete(CODE_KEY);
    }

    @Test
    void 잘못된_코드로는_비밀번호를_변경할_수_없다() {
        // Given
        given(valueOperations.get(CODE_KEY)).willReturn("123456");

        // When
        ApiResponse<Void> response = passwordResetService.resetPassword(EMAIL, "999999", "newPass1!");

        // Then
        assertThat(response.isSuccess()).isFalse();
        then(userRepository).should(never()).findByEmail(anyString());
        then(passwordEncoder).should(never()).encode(anyString());
    }

    @Test
    void 검증_실패_횟수가_한도_미만이면_코드를_유지한다() {
        // Given — 4번째 실패
        given(valueOperations.get(CODE_KEY)).willReturn("123456");
        given(valueOperations.increment(ATTEMPT_KEY))
                .willReturn((long) PasswordResetService.MAX_VERIFY_ATTEMPTS - 1);

        // When
        ApiResponse<Void> response = passwordResetService.verifyCode(EMAIL, "999999");

        // Then — 실패는 하지만 코드는 폐기하지 않음
        assertThat(response.isSuccess()).isFalse();
        then(redisTemplate).should(never()).delete(CODE_KEY);
    }

    @Test
    void 검증_실패가_한도에_도달하면_코드를_폐기한다() {
        // Given — 5번째 실패 (무차별 대입 방지)
        given(valueOperations.get(CODE_KEY)).willReturn("123456");
        given(valueOperations.increment(ATTEMPT_KEY))
                .willReturn((long) PasswordResetService.MAX_VERIFY_ATTEMPTS);

        // When
        ApiResponse<Void> response = passwordResetService.verifyCode(EMAIL, "999999");

        // Then — 코드와 실패 횟수 키 모두 폐기
        assertThat(response.isSuccess()).isFalse();
        then(redisTemplate).should().delete(CODE_KEY);
        then(redisTemplate).should().delete(ATTEMPT_KEY);
    }

    @Test
    void 새_코드를_발급하면_실패_횟수가_초기화된다() {
        // Given
        given(userRepository.existsByEmail(EMAIL)).willReturn(true);
        given(valueOperations.setIfAbsent(eq(COOLDOWN_KEY), anyString(), eq(PasswordResetService.RESEND_COOLDOWN)))
                .willReturn(true);
        given(mailService.send(eq(EMAIL), anyString(), anyString())).willReturn(true);

        // When
        passwordResetService.sendCode(EMAIL);

        // Then
        then(redisTemplate).should().delete(ATTEMPT_KEY);
    }

    // CODE_TTL/RESEND_COOLDOWN/MAX_VERIFY_ATTEMPTS 상수가 의도대로인지 고정 (정책 변경 시 테스트도 함께 갱신)
    @Test
    void 인증코드_정책_상수를_확인한다() {
        assertThat(PasswordResetService.CODE_TTL).isEqualTo(Duration.ofMinutes(5));
        assertThat(PasswordResetService.RESEND_COOLDOWN).isEqualTo(Duration.ofMinutes(1));
        assertThat(PasswordResetService.MAX_VERIFY_ATTEMPTS).isEqualTo(5);
    }
}
