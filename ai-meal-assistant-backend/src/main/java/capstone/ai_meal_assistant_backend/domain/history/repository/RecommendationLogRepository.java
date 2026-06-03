package capstone.ai_meal_assistant_backend.domain.history.repository;

import capstone.ai_meal_assistant_backend.domain.history.entity.RecommendationLog;
import capstone.ai_meal_assistant_backend.domain.menu.entity.Menu;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.Set;

@Repository
public interface RecommendationLogRepository extends JpaRepository<RecommendationLog, Long> {

    @Query("SELECT r.selectedMenu.id FROM RecommendationLog r WHERE r.user = :user AND r.feedbackScore < 0")
    Set<Long> findNegativeMenuIdsByUser(@Param("user") User user);

    @Query("SELECT r FROM RecommendationLog r WHERE r.user = :user AND r.feedbackScore IS NOT NULL ORDER BY r.createdAt DESC")
    List<RecommendationLog> findFeedbacksByUser(@Param("user") User user);

    @Query("SELECT r FROM RecommendationLog r WHERE r.user = :user AND r.aiResultJson IS NOT NULL ORDER BY r.createdAt DESC")
    List<RecommendationLog> findAiPicksByUser(@Param("user") User user);

    Optional<RecommendationLog> findByUserAndSelectedMenu(User user, Menu menu);

    // 회원탈퇴 시 RAG(ChromaDB) 임베딩 정리용 — 사용자의 모든 로그 ID 조회
    @Query("SELECT r.id FROM RecommendationLog r WHERE r.user = :user")
    List<Long> findIdsByUser(@Param("user") User user);

    // 회원탈퇴 시 일괄 삭제
    void deleteByUser(User user);
}
