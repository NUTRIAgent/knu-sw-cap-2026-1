package capstone.ai_meal_assistant_batch.domain.ingredient.repository;

import capstone.ai_meal_assistant_batch.domain.ingredient.entity.IngredientPrice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

// 물가
public interface IngredientPriceRepository extends JpaRepository<IngredientPrice, Long> {

    // 특정 식재료(예: 양파)의 가장 최근(날짜 내림차순) 가격 1개만 가져옴
    Optional<IngredientPrice> findTopByIngredientIdOrderByBaseDateDesc(Long ingredientId);

    Optional<IngredientPrice> findTopByIngredientIdAndSourceApi(Long ingredientId, String sourceApi);

    List<IngredientPrice> findAllBySourceApi(String sourceApi);

    // 미사용 재료 정리 시 연결된 가격 일괄 삭제
    @Modifying
    @Query("DELETE FROM IngredientPrice p WHERE p.ingredient.id IN :ids")
    void deleteByIngredientIdIn(@Param("ids") List<Long> ids);
}
