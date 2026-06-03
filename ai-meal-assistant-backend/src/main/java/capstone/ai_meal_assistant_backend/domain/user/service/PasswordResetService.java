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
    public static final int MAX_VERIFY_ATTEMPTS = 5;                    // 검증 실패 허용 횟수 — 도달 시 코드 폐기 (무차별 대입 방지)
    private static final String CODE_KEY_PREFIX = "pwreset:code:";
    private static final String COOLDOWN_KEY_PREFIX = "pwreset:cooldown:";
    private static final String ATTEMPT_KEY_PREFIX = "pwreset:attempts:";

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
            redisTemplate.delete(ATTEMPT_KEY_PREFIX + email); // 새 코드 발급 시 실패 횟수 초기화

            boolean sent = mailService.send(
                    email,
                    "[메밀] 비밀번호 재설정 인증코드 안내",
                    "안녕하세요, 메밀(Memeal)입니다.\n\n"
                            + "비밀번호 재설정을 위한 인증코드를 보내드려요.\n\n"
                            + "인증코드: " + code + "\n\n"
                            + "이 코드는 " + CODE_TTL.toMinutes() + "분 동안만 유효해요. 시간이 지났다면 인증코드를 다시 요청해 주세요.\n\n"
                            + "본인이 요청하지 않으셨다면 이 메일은 무시하셔도 괜찮아요. 비밀번호는 변경되지 않으니 안심하세요.\n\n"
                            + "오늘도 건강한 식사 되세요!\n"
                            + "메밀 드림"
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
            redisTemplate.delete(ATTEMPT_KEY_PREFIX + email); // 사용한 코드의 실패 횟수도 함께 정리

            return ApiResponse.ok(null);

        } catch (Exception e) {
            log.error("비밀번호 재설정 중 오류 발생", e);
            return ApiResponse.fail("요청 처리 중 오류가 발생했습니다");
        }
    }

    private boolean isCodeValid(String rawEmail, String code) {
        String email = normalize(rawEmail);
        String saved = redisTemplate.opsForValue().get(CODE_KEY_PREFIX + email);
        if (saved == null) {
            return false;
        }
        if (saved.equals(code)) {
            return true;
        }

        // 검증 실패 횟수 누적 — 한도 도달 시 코드 즉시 폐기 (6자리 코드 무차별 대입 방지)
        Long attempts = redisTemplate.opsForValue().increment(ATTEMPT_KEY_PREFIX + email);
        redisTemplate.expire(ATTEMPT_KEY_PREFIX + email, CODE_TTL);
        if (attempts != null && attempts >= MAX_VERIFY_ATTEMPTS) {
            redisTemplate.delete(CODE_KEY_PREFIX + email);
            redisTemplate.delete(ATTEMPT_KEY_PREFIX + email);
            log.warn("인증코드 검증 실패 한도 초과로 코드 폐기: email={}", email);
        }
        return false;
    }

    // 로그인/가입과 동일한 이메일 정규화
    private String normalize(String email) {
        return email.trim().toLowerCase();
    }
}
