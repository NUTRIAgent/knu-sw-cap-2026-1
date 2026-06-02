package capstone.ai_meal_assistant_backend.domain.user.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

// 이메일/닉네임 중복확인 응답
@Getter
@AllArgsConstructor
public class ExistsResponse {
    private boolean exists;
}
