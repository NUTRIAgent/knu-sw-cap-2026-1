package capstone.ai_meal_assistant_backend.domain.user.entity;


import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum Role {

    // Spring Security를 나중에 붙일 거라면 ROLE_ 접두사를 붙여두는 게 기본 관례
    USER("ROLE_USER", "일반 사용자"),
    ADMIN("ROLE_ADMIN", "관리자");

    private final String key;
    private final String description;

}
