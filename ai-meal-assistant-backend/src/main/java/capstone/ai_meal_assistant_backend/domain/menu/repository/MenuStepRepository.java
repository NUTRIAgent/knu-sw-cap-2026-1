package capstone.ai_meal_assistant_backend.domain.menu.repository;

import capstone.ai_meal_assistant_backend.domain.menu.entity.MenuStep;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;

@Repository
public interface MenuStepRepository extends JpaRepository<MenuStep, Long> {

    List<MenuStep> findByMenuIdInOrderByStepOrder(Collection<Long> menuIds);

    List<MenuStep> findByMenuIdOrderByStepOrder(Long menuId);
}
