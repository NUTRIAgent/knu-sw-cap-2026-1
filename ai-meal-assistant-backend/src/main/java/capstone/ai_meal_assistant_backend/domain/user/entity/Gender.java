package capstone.ai_meal_assistant_backend.domain.user.entity;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import lombok.Getter;
import lombok.RequiredArgsConstructor;

import java.util.stream.Stream;

@Getter
@RequiredArgsConstructor
public enum Gender {
    MALE("남성"),
    FEMALE("여성");

    private final String description;

    @JsonValue // 응답 나갈 때 "남성"으로 나감
    public String getDescription() {
        return description;
    }

    @JsonCreator // 요청 들어올 때 "남성" 또는 "MALE"을 Gender.MALE로 바꿈
    public static Gender from(String value) {
        return Stream.of(Gender.values())
                .filter(gender -> gender.description.equals(value) || gender.name().equalsIgnoreCase(value))
                .findFirst()
                .orElse(null);
    }
}