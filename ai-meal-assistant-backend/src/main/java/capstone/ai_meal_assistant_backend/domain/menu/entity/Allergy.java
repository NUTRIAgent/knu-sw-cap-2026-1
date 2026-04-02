package capstone.ai_meal_assistant_backend.domain.menu.entity;

import capstone.ai_meal_assistant_backend.global.entity.BaseEntity;
import jakarta.persistence.*;

@Entity
@Table(name = "allergies")
public class Allergy extends BaseEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name; // 땅콩, 우유 등
}
