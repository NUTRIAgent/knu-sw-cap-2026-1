package capstone.ai_meal_assistant_backend.domain.notification.repository;

import capstone.ai_meal_assistant_backend.domain.ingredient.entity.Ingredient;
import capstone.ai_meal_assistant_backend.domain.notification.entity.UserIngredientAlert;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserIngredientAlertRepository extends JpaRepository<UserIngredientAlert, Long> {

    Optional<UserIngredientAlert> findByUserAndIngredient(User user, Ingredient ingredient);

    List<UserIngredientAlert> findByUser(User user);

    boolean existsByUserAndIngredient(User user, Ingredient ingredient);

    void deleteByUserAndIngredient(User user, Ingredient ingredient);

    /** 특정 재료를 팔로우 중인 모든 사용자의 FCM 토큰 조회 */
    @Query("""
            SELECT t.fcmToken
            FROM UserIngredientAlert a
            JOIN UserDeviceToken t ON t.user = a.user
            WHERE a.ingredient.id = :ingredientId
            """)
    List<String> findFcmTokensByIngredientId(@Param("ingredientId") Long ingredientId);
}
