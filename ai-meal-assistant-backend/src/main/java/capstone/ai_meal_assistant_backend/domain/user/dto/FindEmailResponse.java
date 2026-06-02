package capstone.ai_meal_assistant_backend.domain.user.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

// 아이디(이메일) 찾기 응답 — 마스킹된 이메일 (예: mh***@smail.kongju.ac.kr)
@Getter
@AllArgsConstructor
public class FindEmailResponse {
    private String maskedEmail;
}
