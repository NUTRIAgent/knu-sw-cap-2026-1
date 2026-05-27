package capstone.ai_meal_assistant_batch.domain.menu.repository;

import capstone.ai_meal_assistant_batch.domain.menu.entity.Allergy;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.Set;

// 알레르기 조회용
public interface AllergyRepository extends JpaRepository<Allergy, Long> {
    Optional<Allergy> findByName(String name); // 우유, 땅콩 등으로 검색

    // 표준 목록 이외이면서 user_allergies에 아무도 설정하지 않은 항목만 삭제 (FK 안전)
    @Modifying
    @Query(value = """
            DELETE FROM allergies
            WHERE name NOT IN :names
              AND id NOT IN (SELECT allergy_id FROM user_allergies)
            """, nativeQuery = true)
    void deleteNonStandardUnreferenced(@Param("names") Set<String> names);
}
