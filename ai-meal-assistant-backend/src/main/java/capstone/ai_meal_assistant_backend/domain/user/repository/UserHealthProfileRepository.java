package capstone.ai_meal_assistant_backend.domain.user.repository;

import capstone.ai_meal_assistant_backend.domain.user.entity.UserHealthProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;


// 신체 및 인바디 정보 조회용
public interface UserHealthProfileRepository extends JpaRepository<UserHealthProfile, Long> {

    Optional<UserHealthProfile> findByUserId(Long userId);

}
