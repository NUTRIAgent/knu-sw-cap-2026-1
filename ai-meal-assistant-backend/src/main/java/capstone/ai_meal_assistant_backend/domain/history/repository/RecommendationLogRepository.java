package capstone.ai_meal_assistant_backend.domain.history.repository;

import capstone.ai_meal_assistant_backend.domain.history.entity.RecommendationLog;


import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;


// AI 추천 기록 및 피드백
public interface RecommendationLogRepository extends JpaRepository<RecommendationLog, Long> {

    // 마이페이지에서 과거 추천 기록을 페이징 처리해서 보여줄 때 사용
    @EntityGraph(attributePaths = {"selectedMenu"})
    Page<RecommendationLog> findByUserId(Long userId, Pageable pageable);
}
