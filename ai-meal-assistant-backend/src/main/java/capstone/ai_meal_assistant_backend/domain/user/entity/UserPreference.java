package capstone.ai_meal_assistant_backend.domain.user.entity;

import capstone.ai_meal_assistant_backend.global.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "user_preferences")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class UserPreference extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", unique = true)
    private User user;

    private Integer mealBudget;

    @Enumerated(EnumType.STRING)
    private VegetarianType vegetarianType;

    private Integer spicyPreference; // 1~5단계

    @Enumerated(EnumType.STRING)
    private ProteinLevel proteinLevel;

    @Enumerated(EnumType.STRING)
    @Column(name = "fitness_goal")
    @Builder.Default
    private FitnessGoal fitnessGoal = FitnessGoal.GENERAL;

    @ElementCollection
    @CollectionTable(name = "user_food_preferences", joinColumns = @JoinColumn(name = "user_preference_id"))
    @Column(name = "preference")
    @Builder.Default
    private List<String> foodPreferences = new ArrayList<>();

    public void updatePreference(Integer mealBudget, VegetarianType vegetarianType,
                                 Integer spicyPreference, ProteinLevel proteinLevel,
                                 FitnessGoal fitnessGoal, List<String> foodPreferences) {
        this.mealBudget = mealBudget;
        this.vegetarianType = vegetarianType;
        this.spicyPreference = spicyPreference;
        this.proteinLevel = proteinLevel;
        if (fitnessGoal != null) this.fitnessGoal = fitnessGoal;
        if (foodPreferences != null) {
            this.foodPreferences.clear();
            this.foodPreferences.addAll(foodPreferences);
        }
    }
}
