package capstone.ai_meal_assistant_backend.domain.user.exception;

import lombok.Getter;

// 로그인 연속 실패로 계정이 잠긴 상태에서 로그인 시도 시 발생하는 예외
@Getter
public class AccountLockedException extends RuntimeException {

    private final long remainingSeconds; // 남은 잠금 시간(초)

    public AccountLockedException(long remainingSeconds) {
        super("계정이 잠겨 있습니다");
        this.remainingSeconds = remainingSeconds;
    }
}
