package capstone.ai_meal_assistant_backend.domain.menu.entity;

import capstone.ai_meal_assistant_backend.global.entity.BaseEntity;
import jakarta.persistence.*;
//깃허브 설명서 작성을 위한 주석 추가
@Entity
@Table(name = "menu_allergies")
public class MenuAllergy extends BaseEntity {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "menu_id")
    private Menu menu;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "allergy_id")
    private Allergy allergy;
}
