package capstone.ai_meal_assistant_backend.domain.user.entity;

import capstone.ai_meal_assistant_backend.global.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

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
    private VegetarianType vegetarianType; // enum { NONE, VEGAN, LACTO, 등 }

    private Integer spicyPreference; // 1~5단계

    @Enumerated(EnumType.STRING)
    private ProteinLevel proteinLevel; // enum { LOW, NORMAL, HIGH } (단백질 단계)

    public void updatePreference(Integer mealBudget, VegetarianType vegetarianType,
                               Integer spicyPreference, ProteinLevel proteinLevel) {
        this.mealBudget = mealBudget;
        this.vegetarianType = vegetarianType;
        this.spicyPreference = spicyPreference;
        this.proteinLevel = proteinLevel;
    }
}
