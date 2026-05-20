package capstone.ai_meal_assistant_backend.domain.user.entity;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum FitnessGoal {
    DIET("다이어트"),
    MUSCLE_GAIN("근력증가"),
    MAINTAIN("체중유지"),
    GENERAL("일반식단");

    private final String displayName;
}
