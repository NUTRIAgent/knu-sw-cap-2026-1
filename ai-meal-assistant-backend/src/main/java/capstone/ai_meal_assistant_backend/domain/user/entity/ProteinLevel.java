package capstone.ai_meal_assistant_backend.domain.user.entity;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum ProteinLevel {

    LOW("낮음 (권장량 이하, 신장 질환 등 제한식)"),
    NORMAL("보통 (일반적인 일일 권장량)"),
    HIGH("높음 (근성장 및 다이어트 목적 고단백식)");

    private final String description;
}
