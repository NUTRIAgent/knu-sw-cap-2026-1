package capstone.ai_meal_assistant_backend.domain.user.service;

import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;

/**
 * 로그인 실패 횟수 추적 및 계정 잠금 정책을 담당하는 서비스.
 * 실패 횟수 갱신은 DB 원자적 UPDATE로 처리해 동시 로그인 시도에도
 * 카운트가 누락(lost update)되지 않는다.
 * 추후 Redis 도입 시 이 클래스의 구현만 교체하면 된다.
 */
@Service
@RequiredArgsConstructor
public class LoginAttemptService {

    public static final int MAX_FAILED_ATTEMPTS = 5; // 연속 실패 허용 횟수
    public static final Duration LOCK_DURATION = Duration.ofMinutes(5); // 잠금 유지 시간

    private final UserRepository userRepository;

    // 남은 잠금 시간(초)을 반환. 잠겨 있지 않으면 0
    public long getRemainingLockSeconds(User user) {
        LocalDateTime lockedUntil = user.getLockedUntil();
        if (lockedUntil == null) {
            return 0;
        }
        LocalDateTime now = LocalDateTime.now();
        if (!now.isBefore(lockedUntil)) {
            return 0;
        }
        return Duration.between(now, lockedUntil).getSeconds();
    }

    // 로그인 실패 처리 — 실패 횟수 원자적 누적, 최대치 도달 시 잠금. 이번 실패로 잠겼는지 여부를 반환
    public boolean onLoginFailure(User user) {
        // 만료된 잠금 기록이 남아 있으면 초기화 후 1부터 다시 카운트
        if (user.getLockedUntil() != null && getRemainingLockSeconds(user) == 0) {
            userRepository.resetLoginFailure(user.getId());
        }

        userRepository.incrementFailedLoginCount(user.getId());
        int failedCount = userRepository.findFailedLoginCountById(user.getId());

        if (failedCount >= MAX_FAILED_ATTEMPTS) {
            userRepository.lockUntil(user.getId(), LocalDateTime.now().plus(LOCK_DURATION));
            return true;
        }
        return false;
    }

    // 로그인 성공 처리 — 실패 기록 초기화
    public void onLoginSuccess(User user) {
        if (user.getFailedLoginCount() > 0 || user.getLockedUntil() != null) {
            userRepository.resetLoginFailure(user.getId());
        }
    }
}
