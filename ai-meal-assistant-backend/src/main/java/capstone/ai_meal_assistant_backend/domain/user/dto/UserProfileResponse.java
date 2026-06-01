package capstone.ai_meal_assistant_backend.domain.user.dto;

import capstone.ai_meal_assistant_backend.domain.user.entity.FitnessGoal;
import capstone.ai_meal_assistant_backend.domain.user.entity.Gender;
import capstone.ai_meal_assistant_backend.domain.user.entity.ProteinLevel;
import capstone.ai_meal_assistant_backend.domain.user.entity.VegetarianType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserProfileResponse {

    // 유저 기본 정보 (마이페이지 화면 표시용)
    private String nickname;
    private Gender gender;

    // 건강 정보 (인바디)
    private Double height;
    private Double weight;
    private Double skeletalMuscleMass;
    private Double bodyFatPercentage;
    private Double bmi;
    private Integer bmr;
    private Integer inbodyScore;
    private LocalDate measurementDate;

    // 선호 정보
    private Integer mealBudget;
    private VegetarianType vegetarianType;
    private Integer spicyPreference;
    private ProteinLevel proteinLevel;
    private FitnessGoal fitnessGoal;
    private List<String> foodPreferences;

    // 알러지 정보 (이름 리스트)
    private List<String> allergies;

    // 건강 상태 (예: 고혈압, 당뇨 등)
    private List<String> healthConditions;

    // 자유 입력 선호사항
    private String customNote;
}