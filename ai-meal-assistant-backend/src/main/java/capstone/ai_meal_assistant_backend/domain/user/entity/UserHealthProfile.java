package capstone.ai_meal_assistant_backend.domain.user.entity;

import capstone.ai_meal_assistant_backend.global.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;

@Entity
@Table(name = "user_health_profiles")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class UserHealthProfile extends BaseEntity{
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", unique = true)
    private User user;

    private Double height;
    private Double weight;
    private Double skeletalMuscleMass;
    private Double bodyFatPercentage;

    private Double bmi; // 체질량지수
    private Integer bmr; // 기초대사량
    private Integer inbodyScore; // 인바디 점수
    private LocalDate measurementDate; // 측정 날짜

    public void updateProfile(Double height, Double weight, Double skeletalMuscleMass,
                            Double bodyFatPercentage, Double bmi, Integer bmr,
                            Integer inbodyScore, LocalDate measurementDate) {
        this.height = height;
        this.weight = weight;
        this.skeletalMuscleMass = skeletalMuscleMass;
        this.bodyFatPercentage = bodyFatPercentage;
        this.bmi = bmi;
        this.bmr = bmr;
        this.inbodyScore = inbodyScore;
        this.measurementDate = measurementDate;
    }
}
