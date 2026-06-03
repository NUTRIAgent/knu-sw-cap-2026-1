package capstone.ai_meal_assistant_backend.domain.notification.repository;

import capstone.ai_meal_assistant_backend.domain.notification.entity.UserDeviceToken;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserDeviceTokenRepository extends JpaRepository<UserDeviceToken, Long> {

    Optional<UserDeviceToken> findByUserAndFcmToken(User user, String fcmToken);

    List<UserDeviceToken> findByUser(User user);

    void deleteByUserAndFcmToken(User user, String fcmToken);

    // 회원탈퇴 시 일괄 삭제
    void deleteByUser(User user);
}
