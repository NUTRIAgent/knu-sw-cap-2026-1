package capstone.ai_meal_assistant_backend.domain.user.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.NoArgsConstructor;

// 아이디(이메일) 찾기 요청 — 가입 시 등록한 휴대폰 번호
@Getter
@NoArgsConstructor
public class FindEmailRequest {

    @NotBlank(message = "휴대폰 번호는 필수입니다")
    @Pattern(
            regexp = "^01[016789]\\d{7,8}$",
            message = "올바른 휴대폰 번호 형식이 아닙니다 (숫자만 입력, 예: 01012345678)"
    )
    private String phoneNumber;
}
