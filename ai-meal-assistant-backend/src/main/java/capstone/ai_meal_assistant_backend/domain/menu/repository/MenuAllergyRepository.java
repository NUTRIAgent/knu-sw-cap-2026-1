package capstone.ai_meal_assistant_backend.domain.menu.repository;

import capstone.ai_meal_assistant_backend.domain.menu.entity.Allergy;
import capstone.ai_meal_assistant_backend.domain.menu.entity.MenuAllergy;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Set;

@Repository
public interface MenuAllergyRepository extends JpaRepository<MenuAllergy, Long> {

    @Query("SELECT DISTINCT ma.menu.id FROM MenuAllergy ma WHERE ma.allergy IN :allergies")
    Set<Long> findMenuIdsByAllergyIn(@Param("allergies") List<Allergy> allergies);
}
