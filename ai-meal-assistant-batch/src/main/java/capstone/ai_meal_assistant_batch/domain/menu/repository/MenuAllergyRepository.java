package capstone.ai_meal_assistant_batch.domain.menu.repository;

import capstone.ai_meal_assistant_batch.domain.menu.entity.MenuAllergy;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

// 메뉴에 포함된 알레르기
public interface MenuAllergyRepository extends JpaRepository<MenuAllergy, Long> {

    //  N+1 방지: 메뉴 알레르기 목록을 가져올 때 실제 Allergy 이름까지 한 번에 JOIN 해서 가져옴
    @EntityGraph(attributePaths = {"allergy"})
    List<MenuAllergy> findAllByMenuId(Long menuId);
}
