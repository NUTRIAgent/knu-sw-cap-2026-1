package capstone.ai_meal_assistant_backend.domain.menu.repository;


import capstone.ai_meal_assistant_backend.domain.menu.entity.Allergy;
import capstone.ai_meal_assistant_backend.domain.menu.entity.UserAllergy;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

// 사용자의 알레르기 목룍
public interface UserAllergyRepository extends JpaRepository<UserAllergy, Long> {

    // N+1 방지: 사용자 알레르기 정보를 가죠올 때 실제 알레르기 이름까지 한번에 조인해서 가져옴
    @EntityGraph(attributePaths = {"allergy"})
    List<UserAllergy> findAllByUserId(Long userId);

    void deleteByUserIdAndAllergy(Long userId, Allergy allergyId); // 단건 삭제용
}
