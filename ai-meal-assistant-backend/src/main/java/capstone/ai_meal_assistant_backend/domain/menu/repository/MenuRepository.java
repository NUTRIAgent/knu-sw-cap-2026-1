package capstone.ai_meal_assistant_backend.domain.menu.repository;

import capstone.ai_meal_assistant_backend.domain.menu.entity.Menu;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Set;

@Repository
public interface MenuRepository extends JpaRepository<Menu, Long> {

    @Query(value = """
            SELECT * FROM menus m
            WHERE m.id NOT IN (:excludeIds)
              AND m.category != '후식'
              AND (:budget IS NULL OR m.base_price IS NULL OR m.base_price <= :budget)
              AND (:minPro IS NULL OR m.protein >= :minPro)
              AND (:maxCal IS NULL OR m.calories <= :maxCal)
            ORDER BY RAND()
            LIMIT :limit
            """, nativeQuery = true)
    List<Menu> findCandidates(
            @Param("excludeIds") Set<Long> excludeIds,
            @Param("budget")     Integer budget,
            @Param("minPro")     Double minProtein,
            @Param("maxCal")     Integer maxCalories,
            @Param("limit")      int limit
    );

    @Query(value = """
            SELECT mi.menu_id,
                   GROUP_CONCAT(DISTINCT CONCAT(i.name, ' ', COALESCE(mi.amount_text, ''))
                                ORDER BY i.name SEPARATOR ', ') AS ingredients_text
            FROM menu_ingredients mi
            JOIN ingredients i ON mi.ingredient_id = i.id
            WHERE mi.menu_id IN (:menuIds)
            GROUP BY mi.menu_id
            """, nativeQuery = true)
    List<Object[]> findIngredientsTextByMenuIds(@Param("menuIds") Collection<Long> menuIds);

    /**
     * 메뉴별 재료 비용 산출용 원본 행 조회.
     * row = [menu_id, ingredient_name, required_weight(g), price_per_gram(없으면 null)]
     * 가격 미보유 재료도 포함되도록 LEFT JOIN (NAVER_SHOPPING 소스 기준).
     */
    @Query(value = """
            SELECT mi.menu_id,
                   i.name,
                   mi.required_weight,
                   ip.price_per_gram
            FROM menu_ingredients mi
            JOIN ingredients i ON i.id = mi.ingredient_id
            LEFT JOIN ingredient_prices ip
                   ON ip.ingredient_id = mi.ingredient_id
                  AND ip.source_api = 'NAVER_SHOPPING'
            WHERE mi.menu_id IN (:menuIds)
            ORDER BY mi.menu_id, i.name
            """, nativeQuery = true)
    List<Object[]> findIngredientCostRowsByMenuIds(@Param("menuIds") Collection<Long> menuIds);
}
