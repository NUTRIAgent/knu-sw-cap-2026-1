package capstone.ai_meal_assistant_backend.domain.user.entity;

import capstone.ai_meal_assistant_backend.global.entity.BaseEntity;
import jakarta.persistence.*;
import org.apache.catalina.users.AbstractUser;

@Entity
@Table(name = "users")
public class User extends BaseEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    private String password; // OAuth 가입자는 비밀번호가 없을 수 있으므로 nullable

    @Column(nullable = false)
    private String nickname;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role; // enum Role { USER, ADMIN }

    // --- OAuth 추가 부분 ---
    private String provider; // 예: kakao, google
    private String providerId; // 소셜 로그인 고유 식별자

    // --- 양방향 매핑 (필요시 사용, 기본적으로는 단방향 추천) ---
    @OneToOne(mappedBy = "user", fetch = FetchType.LAZY, cascade = CascadeType.ALL)
    private UserHealthProfile healthProfile;

    @OneToOne(mappedBy = "user", fetch = FetchType.LAZY, cascade = CascadeType.ALL)
    private UserPreference preference;
}
