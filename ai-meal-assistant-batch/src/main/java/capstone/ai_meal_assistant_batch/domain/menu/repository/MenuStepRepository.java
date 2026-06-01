package capstone.ai_meal_assistant_batch.domain.menu.repository;

import capstone.ai_meal_assistant_batch.domain.menu.entity.MenuStep;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Set;

@Repository
public interface MenuStepRepository extends JpaRepository<MenuStep, Long> {

    @Modifying(clearAutomatically = true)
    @Query("DELETE FROM MenuStep s WHERE s.menu.id IN :menuIds")
    void deleteAllByMenuIds(@Param("menuIds") Set<Long> menuIds);
}
