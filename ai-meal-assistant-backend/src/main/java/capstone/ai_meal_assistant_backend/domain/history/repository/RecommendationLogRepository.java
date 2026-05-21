package capstone.ai_meal_assistant_backend.domain.history.repository;

import capstone.ai_meal_assistant_backend.domain.history.entity.RecommendationLog;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Set;

@Repository
public interface RecommendationLogRepository extends JpaRepository<RecommendationLog, Long> {

    @Query("SELECT r.selectedMenu.id FROM RecommendationLog r WHERE r.user = :user AND r.feedbackScore < 0")
    Set<Long> findNegativeMenuIdsByUser(@Param("user") User user);
}
