package capstone.ai_meal_assistant_backend.domain.user.controller;

import capstone.ai_meal_assistant_backend.domain.user.service.AuthService;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final AuthService authService;

    /**
     * 회원가입 화면의 이메일/닉네임 중복확인 API (비로그인 호출 허용)
     * GET /api/v1/users/exists?email=... 또는 ?nickname=...
     */
    @GetMapping("/exists")
    public ResponseEntity<ApiResponse<ExistsResponse>> exists(
            @RequestParam(required = false) String email,
            @RequestParam(required = false) String nickname) {

        if ((email == null || email.isBlank()) && (nickname == null || nickname.isBlank())) {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.fail("email 또는 nickname 파라미터가 필요합니다"));
        }

        boolean exists;
        if (email != null && !email.isBlank()) {
            exists = authService.isEmailTaken(email);
        } else {
            exists = authService.isNicknameTaken(nickname);
        }

        return ResponseEntity.ok(ApiResponse.ok(new ExistsResponse(exists)));
    }

    @Getter
    @AllArgsConstructor
    private static class ExistsResponse {
        private boolean exists;
    }

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
}
