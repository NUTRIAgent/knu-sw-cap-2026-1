package capstone.ai_meal_assistant_backend.domain.user.controller;

import capstone.ai_meal_assistant_backend.domain.user.dto.AuthResponse;
import capstone.ai_meal_assistant_backend.domain.user.exception.AccountLockedException;
import capstone.ai_meal_assistant_backend.domain.user.service.LoginAttemptService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * auth 도메인 한정 예외 핸들러.
 * 다른 컨트롤러들은 각자 응답 포맷(ApiResponse)을 사용 중이므로 전역 적용하지 않는다.
 */
@RestControllerAdvice(assignableTypes = AuthController.class)
public class AuthExceptionHandler {

    // @Valid 검증 실패 시 클라이언트가 파싱 가능한 AuthResponse 포맷으로 변환
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<AuthResponse> handleValidationException(MethodArgumentNotValidException e) {
        String errorMessage = e.getBindingResult().getFieldErrors().stream()
                .findFirst()
                .map(FieldError::getDefaultMessage)
                .orElse("입력값이 올바르지 않습니다");
        return ResponseEntity.badRequest().body(AuthResponse.failure(errorMessage));
    }

    // JSON 파싱 실패(잘못된 enum 값 등) 대응
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<AuthResponse> handleMessageNotReadable(HttpMessageNotReadableException e) {
        return ResponseEntity.badRequest().body(AuthResponse.failure("요청 형식이 올바르지 않습니다"));
    }

    // 로그인 연속 실패로 계정이 잠긴 경우 423 Locked + 남은 시간 안내
    @ExceptionHandler(AccountLockedException.class)
    public ResponseEntity<AuthResponse> handleAccountLocked(AccountLockedException e) {
        long remainingMinutes = Math.max(1, (e.getRemainingSeconds() + 59) / 60); // 올림, 최소 1분으로 표기
        String message = "로그인이 " + LoginAttemptService.MAX_FAILED_ATTEMPTS
                + "회 실패하여 계정이 잠겼습니다. 약 " + remainingMinutes + "분 후 다시 시도해 주세요";
        return ResponseEntity.status(HttpStatus.LOCKED).body(AuthResponse.failure(message));
    }
}
