package capstone.ai_meal_assistant_backend.domain.user.controller;

import capstone.ai_meal_assistant_backend.domain.user.dto.AuthResponse;
import capstone.ai_meal_assistant_backend.domain.user.dto.FindEmailRequest;
import capstone.ai_meal_assistant_backend.domain.user.dto.FindEmailResponse;
import capstone.ai_meal_assistant_backend.domain.user.dto.LoginRequest;
import capstone.ai_meal_assistant_backend.domain.user.dto.PasswordCodeRequest;
import capstone.ai_meal_assistant_backend.domain.user.dto.PasswordResetRequest;
import capstone.ai_meal_assistant_backend.domain.user.dto.PasswordVerifyRequest;
import capstone.ai_meal_assistant_backend.domain.user.dto.RefreshRequest;
import capstone.ai_meal_assistant_backend.domain.user.dto.SignupRequest;
import capstone.ai_meal_assistant_backend.domain.user.service.AuthService;
import capstone.ai_meal_assistant_backend.domain.user.service.PasswordResetService;
import capstone.ai_meal_assistant_backend.global.dto.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final PasswordResetService passwordResetService;

    @PostMapping("/signup")
    public ResponseEntity<AuthResponse> signup(@Valid @RequestBody SignupRequest request) {
        AuthResponse response = authService.signup(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/refresh")
    public ResponseEntity<AuthResponse> refresh(@Valid @RequestBody RefreshRequest request) {
        AuthResponse response = authService.refresh(request);
        return ResponseEntity.ok(response);
    }

    // 아이디(이메일) 찾기 — 가입 시 등록한 휴대폰 번호로 마스킹된 이메일 조회
    @PostMapping("/find-email")
    public ResponseEntity<ApiResponse<FindEmailResponse>> findEmail(@Valid @RequestBody FindEmailRequest request) {
        return authService.findMaskedEmailByPhoneNumber(request.getPhoneNumber())
                .map(masked -> ResponseEntity.ok(ApiResponse.ok(new FindEmailResponse(masked))))
                .orElseGet(() -> ResponseEntity.ok(
                        ApiResponse.fail("해당 휴대폰 번호로 가입된 계정을 찾을 수 없습니다")));
    }

    // 비밀번호 재설정 인증코드 발송
    @PostMapping("/password/code")
    public ResponseEntity<ApiResponse<Void>> sendPasswordCode(@Valid @RequestBody PasswordCodeRequest request) {
        return ResponseEntity.ok(passwordResetService.sendCode(request.getEmail()));
    }

    // 비밀번호 재설정 인증코드 검증 (새 비밀번호 입력 화면 진입 전 확인용)
    @PostMapping("/password/verify")
    public ResponseEntity<ApiResponse<Void>> verifyPasswordCode(@Valid @RequestBody PasswordVerifyRequest request) {
        return ResponseEntity.ok(passwordResetService.verifyCode(request.getEmail(), request.getCode()));
    }

    // 비밀번호 재설정
    @PostMapping("/password/reset")
    public ResponseEntity<ApiResponse<Void>> resetPassword(@Valid @RequestBody PasswordResetRequest request) {
        return ResponseEntity.ok(passwordResetService.resetPassword(
                request.getEmail(), request.getCode(), request.getNewPassword()));
    }
}
