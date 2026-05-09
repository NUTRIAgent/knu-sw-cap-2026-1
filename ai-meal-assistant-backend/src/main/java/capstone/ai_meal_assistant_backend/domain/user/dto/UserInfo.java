package capstone.ai_meal_assistant_backend.domain.user.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class UserInfo {
    private String email;
    private String nickname;
}
