package capstone.ai_meal_assistant_backend.domain.user.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class UserInfo {
    private String email;
    private String nickname;
    private String gender; // Gender enum 이름(MALE/FEMALE) — 클라이언트가 로컬 저장에 사용
}
