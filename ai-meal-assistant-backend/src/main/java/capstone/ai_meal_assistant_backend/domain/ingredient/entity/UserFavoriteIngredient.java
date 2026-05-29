package capstone.ai_meal_assistant_backend.domain.ingredient.entity;

import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.global.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(
        name = "user_favorite_ingredients",
        uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "ingredient_id"})
)
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class UserFavoriteIngredient extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ingredient_id", nullable = false)
    private Ingredient ingredient;
}
