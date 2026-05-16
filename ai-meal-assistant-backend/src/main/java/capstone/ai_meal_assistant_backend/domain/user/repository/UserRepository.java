package capstone.ai_meal_assistant_backend.domain.user.repository;

import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

// 회원가입, 로그인용
public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);    // 이메일 중복 확인

}
