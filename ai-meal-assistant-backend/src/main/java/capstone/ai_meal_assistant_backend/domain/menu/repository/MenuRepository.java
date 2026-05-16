package capstone.ai_meal_assistant_backend.domain.menu.repository;

import capstone.ai_meal_assistant_backend.domain.menu.entity.Menu;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

// 메뉴 기본 정보
public interface MenuRepository extends JpaRepository<Menu, Long> {

    Optional<Menu> findByFoodCode(String foodCode); // 식약처 API 중복 데이터 방지용
}
