package capstone.ai_meal_assistant_backend.domain.ingredient.repository;

import capstone.ai_meal_assistant_backend.domain.ingredient.entity.UserFavoriteIngredient;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface UserFavoriteIngredientRepository extends JpaRepository<UserFavoriteIngredient, Long> {

    boolean existsByUserIdAndIngredientId(Long userId, Long ingredientId);

    // 회원탈퇴 시 일괄 삭제
    void deleteByUser(User user);

    void deleteByUserIdAndIngredientId(Long userId, Long ingredientId);

    @Query("SELECT f.ingredient.id FROM UserFavoriteIngredient f WHERE f.user.id = :userId")
    List<Long> findIngredientIdsByUserId(@Param("userId") Long userId);
}
