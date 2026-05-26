package capstone.ai_meal_assistant_backend.domain.ingredient.repository;

import capstone.ai_meal_assistant_backend.domain.ingredient.entity.IngredientPrice;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface IngredientPriceRepository extends JpaRepository<IngredientPrice, Long> {

    @Query("""
            SELECT ip FROM IngredientPrice ip
            JOIN FETCH ip.ingredient i
            WHERE i.name = :name
            ORDER BY ip.baseDate DESC, ip.id DESC
            """)
    List<IngredientPrice> findLatestByIngredientName(@Param("name") String name, Pageable pageable);
}
