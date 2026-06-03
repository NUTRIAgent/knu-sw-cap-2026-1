package capstone.ai_meal_assistant_backend.domain.user.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;

// 비밀번호 재설정 요청 — 인증코드 확인 후 새 비밀번호 설정
@Getter
@NoArgsConstructor
public class PasswordResetRequest {

    @NotBlank(message = "이메일은 필수입니다")
    @Email(message = "올바른 이메일 형식이 아닙니다")
    private String email;

    @NotBlank(message = "인증코드는 필수입니다")
    private String code;

    // 비밀번호 정책은 회원가입(SignupRequest)과 동일하게 유지
    @NotBlank(message = "새 비밀번호는 필수입니다")
    @Size(min = 8, max = 64, message = "비밀번호는 8자 이상 64자 이하여야 합니다")
    @Pattern(
            regexp = "^(?=.*[A-Za-z])(?=.*\\d)(?=.*[^A-Za-z0-9\\s])\\S+$",
            message = "비밀번호는 영문, 숫자, 특수문자를 각각 1자 이상 포함해야 합니다"
    )
    private String newPassword;
}
