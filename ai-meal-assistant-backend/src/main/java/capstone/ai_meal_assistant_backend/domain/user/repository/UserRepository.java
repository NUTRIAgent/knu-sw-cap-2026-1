package capstone.ai_meal_assistant_backend.domain.user.repository;

import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
    boolean existsByNickname(String nickname);

    // --- 로그인 브루트포스 방지: 동시 로그인 시도에도 카운트가 누락되지 않도록(lost update 방지) DB 원자적 갱신 사용 ---

    @Modifying(clearAutomatically = true)
    @Query("UPDATE User u SET u.failedLoginCount = u.failedLoginCount + 1 WHERE u.id = :id")
    void incrementFailedLoginCount(@Param("id") Long id);

    @Query("SELECT u.failedLoginCount FROM User u WHERE u.id = :id")
    int findFailedLoginCountById(@Param("id") Long id);

    @Modifying(clearAutomatically = true)
    @Query("UPDATE User u SET u.lockedUntil = :until WHERE u.id = :id")
    void lockUntil(@Param("id") Long id, @Param("until") LocalDateTime until);

    @Modifying(clearAutomatically = true)
    @Query("UPDATE User u SET u.failedLoginCount = 0, u.lockedUntil = null WHERE u.id = :id")
    void resetLoginFailure(@Param("id") Long id);
}
