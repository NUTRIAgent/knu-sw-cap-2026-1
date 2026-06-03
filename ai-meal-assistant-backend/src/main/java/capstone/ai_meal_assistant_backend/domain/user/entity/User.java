package capstone.ai_meal_assistant_backend.domain.user.entity;

import capstone.ai_meal_assistant_backend.global.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class User extends BaseEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    private String password;

    @Column(nullable = false, unique = true)
    private String nickname;

    // --- 추가된 성별 필드 ---
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Gender gender;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    private String provider;
    private String providerId;

    // --- 로그인 브루트포스 방지 필드 ---
    @Column(nullable = false)
    @Builder.Default
    private int failedLoginCount = 0;

    private LocalDateTime lockedUntil;

    @OneToOne(mappedBy = "user", fetch = FetchType.LAZY, cascade = CascadeType.ALL)
    private UserHealthProfile healthProfile;

    @OneToOne(mappedBy = "user", fetch = FetchType.LAZY, cascade = CascadeType.ALL)
    private UserPreference preference;

    public void updateNicknameAndGender(String nickname, Gender gender) {
        this.nickname = nickname;
        this.gender = gender;
    }

    // 로그인 실패 횟수 증가
    public void increaseFailedLoginCount() {
        this.failedLoginCount++;
    }

    // 지정 시각까지 계정 잠금
    public void lockUntil(LocalDateTime until) {
        this.lockedUntil = until;
    }

    // 로그인 실패 기록 초기화 (성공 또는 잠금 만료 시)
    public void resetLoginFailure() {
        this.failedLoginCount = 0;
        this.lockedUntil = null;
    }
}
