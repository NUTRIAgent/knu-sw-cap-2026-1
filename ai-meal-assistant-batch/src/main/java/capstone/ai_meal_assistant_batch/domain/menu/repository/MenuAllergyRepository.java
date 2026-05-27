package capstone.ai_meal_assistant_batch.domain.menu.repository;

import capstone.ai_meal_assistant_batch.domain.menu.entity.MenuAllergy;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Set;

// 메뉴에 포함된 알레르기
public interface MenuAllergyRepository extends JpaRepository<MenuAllergy, Long> {

    //  N+1 방지: 메뉴 알레르기 목록을 가져올 때 실제 Allergy 이름까지 한 번에 JOIN 해서 가져옴
    @EntityGraph(attributePaths = {"allergy"})
    List<MenuAllergy> findAllByMenuId(Long menuId);

    // STEP 4 멱등 보장: 기존 (menu_id, allergy_id) 쌍을 "menuId_allergyId" 문자열 Set으로 반환
    @Query("SELECT CONCAT(ma.menu.id, '_', ma.allergy.id) FROM MenuAllergy ma")
    Set<String> findAllKeys();
}
