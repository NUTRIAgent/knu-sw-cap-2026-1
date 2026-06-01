package capstone.ai_meal_assistant_batch.domain.ingredient.repository;

import capstone.ai_meal_assistant_batch.domain.ingredient.entity.IngredientKamisMapping;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface IngredientKamisMappingRepository extends JpaRepository<IngredientKamisMapping, Long> {

    List<IngredientKamisMapping> findAllByConfirmedTrue();

    boolean existsByIngredientIdAndConfirmedTrue(Long ingredientId);

    boolean existsByIngredientIdAndKamisItemCode(Long ingredientId, String kamisItemCode);

    // 미사용 재료 정리 시 연결된 KAMIS 매핑 일괄 삭제
    @Modifying
    @Query("DELETE FROM IngredientKamisMapping m WHERE m.ingredient.id IN :ids")
    void deleteByIngredientIdIn(@Param("ids") List<Long> ids);
}
