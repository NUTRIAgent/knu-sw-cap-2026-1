package capstone.ai_meal_assistant_backend.domain.notification.entity;

import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.global.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(
    name = "user_device_tokens",
    uniqueConstraints = @UniqueConstraint(
        name = "uq_user_device_token",
        columnNames = {"user_id", "fcm_token"}
    )
)
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PRIVATE)
@Builder
public class UserDeviceToken extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 512)
    private String fcmToken;

    @Column(nullable = false, length = 10)
    private String platform; // "ios" | "android"
}
