package capstone.ai_meal_assistant_backend.domain.history.entity;

import capstone.ai_meal_assistant_backend.domain.menu.entity.Menu;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.global.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.List;

@Entity
@Table(
    name = "recommendation_logs",
    indexes = @Index(name = "idx_rec_log_user_score", columnList = "user_id, feedback_score")
)
@Getter
@Setter
@NoArgsConstructor
public class RecommendationLog extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "json")
    private List<Long> recommendedMenuIds;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "selected_menu_id", nullable = false)
    private Menu selectedMenu;

    // 1 = 긍정, -1 = 부정 (후보 메뉴 좋아요/싫어요 — 다음 추천 필터링에 사용)
    private Integer feedbackScore;

    // 1~5 별점 (AI 픽 만족도 — 추후 RAG/분석용)
    private Integer starRating;

    @Column(columnDefinition = "TEXT")
    private String feedbackReason;
}
