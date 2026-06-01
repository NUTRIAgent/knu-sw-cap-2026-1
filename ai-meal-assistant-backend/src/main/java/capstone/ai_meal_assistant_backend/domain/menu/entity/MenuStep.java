package capstone.ai_meal_assistant_backend.domain.menu.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "menu_steps")
@Getter
@NoArgsConstructor
public class MenuStep {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "menu_id", nullable = false)
    private Menu menu;

    @Column(nullable = false)
    private int stepOrder;

    @Column(length = 2000)
    private String description;

    @Column(length = 500)
    private String imageUrl;
}
