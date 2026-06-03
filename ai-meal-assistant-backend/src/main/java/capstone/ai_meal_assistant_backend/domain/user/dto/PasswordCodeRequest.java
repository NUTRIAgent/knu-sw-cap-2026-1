package capstone.ai_meal_assistant_backend.domain.user.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;

// 비밀번호 재설정 인증코드 발송 요청
@Getter
@NoArgsConstructor
public class PasswordCodeRequest {

    @NotBlank(message = "이메일은 필수입니다")
    @Email(message = "올바른 이메일 형식이 아닙니다")
    private String email;
}
