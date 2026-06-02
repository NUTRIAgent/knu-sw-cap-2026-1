package capstone.ai_meal_assistant_backend.domain.user.controller;

import capstone.ai_meal_assistant_backend.domain.user.dto.UserProfileRequest;
import capstone.ai_meal_assistant_backend.domain.user.dto.UserProfileResponse;
import capstone.ai_meal_assistant_backend.domain.user.service.UserProfileService;
import capstone.ai_meal_assistant_backend.global.security.JwtUtil;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserProfileController {

    private final UserProfileService userProfileService;
    private final JwtUtil jwtUtil;

    @Getter
    @AllArgsConstructor
    private static class ApiResponse<T> {
        private boolean success;
        private T data;
        private String error;

        static <T> ApiResponse<T> ok(T data) {
            return new ApiResponse<>(true, data, null);
        }

        static <T> ApiResponse<T> fail(String error) {
            return new ApiResponse<>(false, null, error);
        }
    }

    /**
     * 사용자 프로필 저장 또는 수정
     * - 인바디 정보
     * - 음식 선호 정보
     * - 알러지 정보
     */
    @PostMapping("/profile")
    public ResponseEntity<ApiResponse<UserProfileResponse>> saveProfile(
            @RequestHeader("Authorization") String authHeader,
            @Valid @RequestBody UserProfileRequest request) {

        String email = extractEmailFromToken(authHeader);
        UserProfileResponse response = userProfileService.saveOrUpdateProfile(email, request);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    /**
     * 사용자 프로필 수정 (PUT 방식)
     */
    @PutMapping("/profile")
    public ResponseEntity<ApiResponse<UserProfileResponse>> updateProfile(
            @RequestHeader("Authorization") String authHeader,
            @Valid @RequestBody UserProfileRequest request) {

        String email = extractEmailFromToken(authHeader);
        UserProfileResponse response = userProfileService.saveOrUpdateProfile(email, request);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    /**
     * 사용자 프로필 조회
     */
    @GetMapping("/profile")
    public ResponseEntity<ApiResponse<UserProfileResponse>> getProfile(
            @RequestHeader("Authorization") String authHeader) {

        String email = extractEmailFromToken(authHeader);
        UserProfileResponse response = userProfileService.getProfile(email);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    /**
     * @Valid 검증 실패 시 이 컨트롤러의 ApiResponse 포맷으로 400 응답
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleValidationException(MethodArgumentNotValidException e) {
        String errorMessage = e.getBindingResult().getFieldErrors().stream()
                .findFirst()
                .map(FieldError::getDefaultMessage)
                .orElse("입력값이 올바르지 않습니다");
        return ResponseEntity.badRequest().body(ApiResponse.fail(errorMessage));
    }

    /**
     * Authorization 헤더에서 이메일 추출
     */
    private String extractEmailFromToken(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new IllegalArgumentException("유효하지 않은 인증 헤더입니다.");
        }
        String token = authHeader.substring(7);
        return jwtUtil.getEmailFromToken(token);
    }
}