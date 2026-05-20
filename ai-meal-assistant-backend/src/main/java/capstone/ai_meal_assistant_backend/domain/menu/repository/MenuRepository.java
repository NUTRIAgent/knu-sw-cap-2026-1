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
            WHERE (:excludeIds IS NULL OR m.id NOT IN (:excludeIds))
              AND (:budget   IS NULL OR m.base_price IS NULL OR m.base_price <= :budget)
              AND (:minPro   IS NULL OR m.protein >= :minPro)
              AND (:maxCal   IS NULL OR m.calories <= :maxCal)
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
                   GROUP_CONCAT(CONCAT(i.name, ' ', COALESCE(mi.amount_text, ''))
                                ORDER BY i.name SEPARATOR ', ') AS ingredients_text
            FROM menu_ingredients mi
            JOIN ingredients i ON mi.ingredient_id = i.id
            WHERE mi.menu_id IN (:menuIds)
            GROUP BY mi.menu_id
            """, nativeQuery = true)
    List<Object[]> findIngredientsTextByMenuIds(@Param("menuIds") Collection<Long> menuIds);
}
