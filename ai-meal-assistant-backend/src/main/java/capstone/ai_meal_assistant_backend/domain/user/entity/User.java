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

    // 아이디(이메일) 찾기용 휴대폰 번호 — 기존 가입자를 고려해 nullable (숫자만 저장, 예: 01012345678)
    @Column(unique = true)
    private String phoneNumber;

    // --- 로그인 브루트포스 방지 필드 ---
    // 갱신은 UserRepository의 원자적 UPDATE 쿼리로만 수행 (동시 로그인 시도 시 lost update 방지)
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

    // 비밀번호 재설정 (비밀번호 찾기에서 사용)
    public void changePassword(String encodedPassword) {
        this.password = encodedPassword;
    }
}
