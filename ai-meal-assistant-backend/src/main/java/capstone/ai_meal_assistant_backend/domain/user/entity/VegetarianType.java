package capstone.ai_meal_assistant_backend.domain.user.entity;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum VegetarianType {

    NONE("해당 없음 (일반식)"),
    FLEXITARIAN("플렉시테리언 (평소엔 채식, 가끔 육식)"),
    POLLO("폴로 (가금류, 페스코 허용)"),
    PESCO("페스코 (해산물, 락토 오보 허용)"),
    LACTO_OVO("락토 오보 (달걀, 유제품 허용)"),
    OVO("오보 (달걀 허용)"),
    LACTO("락토 (유제품 허용)"),
    VEGAN("비건 (완전 채식)");

    private final String description;
}
