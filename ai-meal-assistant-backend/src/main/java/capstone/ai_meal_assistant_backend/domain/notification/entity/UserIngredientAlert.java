package capstone.ai_meal_assistant_backend.domain.notification.entity;

import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.global.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(
    name = "user_ingredient_alerts",
    uniqueConstraints = @UniqueConstraint(
        name = "uq_user_kamis_alert",
        columnNames = {"user_id", "kamis_item_code"}
    )
)
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@Builder
public class UserIngredientAlert extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "kamis_item_code", nullable = false, length = 50)
    private String kamisItemCode;

    @Column(name = "kamis_item_name", nullable = false, length = 100)
    private String kamisItemName;
}
