package capstone.ai_meal_assistant_backend.domain.user.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class AuthResponse {
    private boolean success;
    private AuthData data;
    private String error;
    
    // 성공 응답
    public static AuthResponse success(AuthData data) {
        return new AuthResponse(true, data, null);
    }
    
    // 실패 응답
    public static AuthResponse failure(String error) {
        return new AuthResponse(false, null, error);
    }
}
