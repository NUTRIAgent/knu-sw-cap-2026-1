package capstone.ai_meal_assistant_backend.domain.menu.repository;

import capstone.ai_meal_assistant_backend.domain.menu.entity.Allergy;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

// 알레르기 조회용
public interface AllergyRepository extends JpaRepository<Allergy, Long> {
    Optional<Allergy> findByName(String name); // 우유, 땅콩 등으로 검색
}
