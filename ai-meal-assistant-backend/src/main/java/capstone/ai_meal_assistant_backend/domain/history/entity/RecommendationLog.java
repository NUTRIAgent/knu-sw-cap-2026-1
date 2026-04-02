package capstone.ai_meal_assistant_backend.domain.history.entity;

import capstone.ai_meal_assistant_backend.domain.menu.entity.Menu;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.global.entity.BaseEntity;
import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.util.List;

@Entity
@Table(name = "recommendation_logs")
public class RecommendationLog extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    // ★ 최신 하이버네이트 6 (스프링 부트 3.x) JSON 컬럼 매핑 방식 ★
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "json")
    private List<Long> recommendedMenuIds; // AI가 추천했던 메뉴 ID 리스트를 JSON 배열로 저장

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "selected_menu_id")
    private Menu selectedMenu;

    private Integer feedbackScore;

    @Column(columnDefinition = "TEXT")
    private String feedbackReason; // RAG 검색 재료용
}
