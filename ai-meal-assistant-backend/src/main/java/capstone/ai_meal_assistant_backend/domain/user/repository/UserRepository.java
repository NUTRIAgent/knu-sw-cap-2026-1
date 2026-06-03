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

    // 실패 1회 기록 — 잠금이 만료된 상태면 초기화 후 1부터, 아니면 +1.
    // 만료 판정과 갱신을 단일 쿼리로 묶어 만료 직후 동시 실패가 몰려도 과소 집계되지 않는다 (행 잠금으로 직렬화)
    @Modifying(clearAutomatically = true)
    @Query("UPDATE User u SET "
            + "u.failedLoginCount = CASE WHEN u.lockedUntil IS NOT NULL AND u.lockedUntil <= :now THEN 1 ELSE u.failedLoginCount + 1 END, "
            + "u.lockedUntil = CASE WHEN u.lockedUntil IS NOT NULL AND u.lockedUntil <= :now THEN NULL ELSE u.lockedUntil END "
            + "WHERE u.id = :id")
    void recordLoginFailure(@Param("id") Long id, @Param("now") LocalDateTime now);

    @Query("SELECT u.failedLoginCount FROM User u WHERE u.id = :id")
    int findFailedLoginCountById(@Param("id") Long id);

    @Modifying(clearAutomatically = true)
    @Query("UPDATE User u SET u.lockedUntil = :until WHERE u.id = :id")
    void lockUntil(@Param("id") Long id, @Param("until") LocalDateTime until);

    @Modifying(clearAutomatically = true)
    @Query("UPDATE User u SET u.failedLoginCount = 0, u.lockedUntil = null WHERE u.id = :id")
    void resetLoginFailure(@Param("id") Long id);
}
