package capstone.ai_meal_assistant_backend.domain.user.service;

import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.domain.user.repository.UserRepository;
import capstone.ai_meal_assistant_backend.global.dto.ApiResponse;
import capstone.ai_meal_assistant_backend.global.mail.MailService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Duration;

/**
 * 비밀번호 찾기(재설정) — 이메일 인증코드 발송/검증/재설정.
 * 인증코드는 Redis에 TTL과 함께 저장한다 (만료 자동 처리, 1회용).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PasswordResetService {

    public static final Duration CODE_TTL = Duration.ofMinutes(5);      // 인증코드 유효시간
    public static final Duration RESEND_COOLDOWN = Duration.ofMinutes(1); // 재발송 제한 간격
    private static final String CODE_KEY_PREFIX = "pwreset:code:";
    private static final String COOLDOWN_KEY_PREFIX = "pwreset:cooldown:";

    private final UserRepository userRepository;
    private final StringRedisTemplate redisTemplate;
    private final MailService mailService;
    private final PasswordEncoder passwordEncoder;
    private final SecureRandom secureRandom = new SecureRandom();

    // 인증코드 발송 — 가입 이메일 확인 → 재발송 제한 → 코드 저장 → 메일 발송
    public ApiResponse<Void> sendCode(String rawEmail) {
        try {
            String email = normalize(rawEmail);

            if (!userRepository.existsByEmail(email)) {
                return ApiResponse.fail("가입되지 않은 이메일입니다");
            }

            // 재발송 제한 (1분) — 키가 이미 있으면 최근에 발송한 것
            Boolean firstRequest = redisTemplate.opsForValue()
                    .setIfAbsent(COOLDOWN_KEY_PREFIX + email, "1", RESEND_COOLDOWN);
            if (Boolean.FALSE.equals(firstRequest)) {
                return ApiResponse.fail("잠시 후 다시 요청해 주세요 (재발송은 1분 간격)");
            }

            String code = String.format("%06d", secureRandom.nextInt(1_000_000));
            redisTemplate.opsForValue().set(CODE_KEY_PREFIX + email, code, CODE_TTL);

            boolean sent = mailService.send(
                    email,
                    "[NUTRI Agent] 비밀번호 재설정 인증코드",
                    "비밀번호 재설정 인증코드: " + code
                            + "\n유효시간은 5분입니다."
                            + "\n본인이 요청하지 않았다면 이 메일을 무시해 주세요."
            );
            if (!sent) {
                return ApiResponse.fail("메일 발송에 실패했습니다. 잠시 후 다시 시도해 주세요");
            }

            return ApiResponse.ok(null);

        } catch (Exception e) {
            log.error("인증코드 발송 중 오류 발생", e);
            return ApiResponse.fail("요청 처리 중 오류가 발생했습니다");
        }
    }

    // 인증코드 사전 검증 (UX용 — 코드를 소비하지 않음, 실제 소비는 resetPassword에서)
    public ApiResponse<Void> verifyCode(String rawEmail, String code) {
        try {
            if (isCodeValid(rawEmail, code)) {
                return ApiResponse.ok(null);
            }
            return ApiResponse.fail("인증코드가 일치하지 않거나 만료되었습니다");
        } catch (Exception e) {
            log.error("인증코드 검증 중 오류 발생", e);
            return ApiResponse.fail("요청 처리 중 오류가 발생했습니다");
        }
    }

    // 비밀번호 재설정 — 코드 재검증 후 변경, 사용한 코드는 즉시 폐기 (1회용)
    @Transactional
    public ApiResponse<Void> resetPassword(String rawEmail, String code, String newPassword) {
        try {
            String email = normalize(rawEmail);

            if (!isCodeValid(email, code)) {
                return ApiResponse.fail("인증코드가 일치하지 않거나 만료되었습니다");
            }

            User user = userRepository.findByEmail(email).orElse(null);
            if (user == null) {
                return ApiResponse.fail("가입되지 않은 이메일입니다");
            }

            user.changePassword(passwordEncoder.encode(newPassword));
            redisTemplate.delete(CODE_KEY_PREFIX + email);

            return ApiResponse.ok(null);

        } catch (Exception e) {
            log.error("비밀번호 재설정 중 오류 발생", e);
            return ApiResponse.fail("요청 처리 중 오류가 발생했습니다");
        }
    }

    private boolean isCodeValid(String rawEmail, String code) {
        String saved = redisTemplate.opsForValue().get(CODE_KEY_PREFIX + normalize(rawEmail));
        return saved != null && saved.equals(code);
    }

    // 로그인/가입과 동일한 이메일 정규화
    private String normalize(String email) {
        return email.trim().toLowerCase();
    }
}
