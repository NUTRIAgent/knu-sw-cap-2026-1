package capstone.ai_meal_assistant_backend.domain.notification.repository;

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

    Optional<UserIngredientAlert> findByUserAndKamisItemCode(User user, String kamisItemCode);

    List<UserIngredientAlert> findByUser(User user);

    boolean existsByUserAndKamisItemCode(User user, String kamisItemCode);

    void deleteByUserAndKamisItemCode(User user, String kamisItemCode);

    // 회원탈퇴 시 일괄 삭제
    void deleteByUser(User user);

    /** 특정 KAMIS 코드를 팔로우 중인 모든 사용자의 FCM 토큰 조회 */
    @Query("""
            SELECT t.fcmToken
            FROM UserIngredientAlert a
            JOIN UserDeviceToken t ON t.user = a.user
            WHERE a.kamisItemCode = :kamisItemCode
            """)
    List<String> findFcmTokensByKamisItemCode(@Param("kamisItemCode") String kamisItemCode);
}
