package capstone.ai_meal_assistant_backend.domain.user.controller;

import capstone.ai_meal_assistant_backend.domain.user.dto.ExistsResponse;
import capstone.ai_meal_assistant_backend.domain.user.service.AccountDeletionService;
import capstone.ai_meal_assistant_backend.domain.user.service.AuthService;
import capstone.ai_meal_assistant_backend.global.dto.ApiResponse;
import capstone.ai_meal_assistant_backend.global.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final AuthService authService;
    private final AccountDeletionService accountDeletionService;
    private final JwtUtil jwtUtil;

    /**
     * 회원가입 화면의 이메일/닉네임/휴대폰 번호 중복확인 API (비로그인 호출 허용)
     * GET /api/v1/users/exists?email=... 또는 ?nickname=... 또는 ?phoneNumber=...
     */
    @GetMapping("/exists")
    public ResponseEntity<ApiResponse<ExistsResponse>> exists(
            @RequestParam(required = false) String email,
            @RequestParam(required = false) String nickname,
            @RequestParam(required = false) String phoneNumber) {

        boolean exists;
        if (email != null && !email.isBlank()) {
            exists = authService.isEmailTaken(email);
        } else if (nickname != null && !nickname.isBlank()) {
            exists = authService.isNicknameTaken(nickname);
        } else if (phoneNumber != null && !phoneNumber.isBlank()) {
            exists = authService.isPhoneNumberTaken(phoneNumber);
        } else {
            return ResponseEntity.badRequest()
                    .body(ApiResponse.fail("email, nickname 또는 phoneNumber 파라미터가 필요합니다"));
        }

        return ResponseEntity.ok(ApiResponse.ok(new ExistsResponse(exists)));
    }

    /**
     * 회원탈퇴 — Bearer access token으로 본인 확인 후 계정과 연관 데이터를 모두 삭제
     * DELETE /api/v1/users/me
     */
    @DeleteMapping("/me")
    public ResponseEntity<ApiResponse<Void>> deleteMe(
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.fail("유효하지 않은 인증 헤더입니다"));
        }
        String token = authHeader.substring(7);
        if (!jwtUtil.validateToken(token)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(ApiResponse.fail("유효하지 않은 토큰입니다"));
        }
        String email = jwtUtil.getEmailFromToken(token);
        return ResponseEntity.ok(accountDeletionService.deleteAccount(email));
    }
}
