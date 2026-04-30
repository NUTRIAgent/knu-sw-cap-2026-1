package capstone.ai_meal_assistant_backend.domain.user.repository;

import capstone.ai_meal_assistant_backend.domain.user.entity.UserPreference;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

// 예산, 비건, 단백질 단계 조회용
public interface UserPreferenceRepository extends JpaRepository<UserPreference, Long> {

    Optional<UserPreference> findByUserId(Long userId);
}
