package capstone.ai_meal_assistant_batch.domain.menu.repository;

import capstone.ai_meal_assistant_batch.domain.menu.entity.MenuIngredient;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

// 메뉴의 레시피 정보
public interface MenuIngredientRepository extends JpaRepository<MenuIngredient, Long> {

    // 예: 제육덮밥의 재료를 꺼낼 때 Ingredient(돼지고기, 양파) 엔티티까지 한 번에 조인 (가격 계산 시 필수)
    @EntityGraph(attributePaths = {"ingredient"})
    List<MenuIngredient> findAllByMenuId(Long menuId);

    // STEP 4 용: 전체 menu_ingredients를 menu·ingredient 포함해서 한 번에 조회 (N+1 방지)
    @Query("SELECT mi FROM MenuIngredient mi JOIN FETCH mi.menu JOIN FETCH mi.ingredient")
    List<MenuIngredient> findAllWithMenuAndIngredient();
}
