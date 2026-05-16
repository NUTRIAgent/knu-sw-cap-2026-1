package capstone.ai_meal_assistant_backend.domain.ingredient.entity;

import capstone.ai_meal_assistant_backend.global.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "ingredients", indexes = {
        @Index(name = "idx_ingredient_name", columnList = "name")   // 이름 검색 속도 최적화
})
@Getter
@Builder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PRIVATE)
// 식재료 테이블
public class Ingredient extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name;

    private String standardUnit;    // 기준 단위 (예: 1kg, 100g)

    // 캐싱용 최신 물가 (매일 배치 작업이나 Redis에서 업데이트, 물가 API 장애 시 대비용)
    private Integer latestPrice;

    // 양방향 매핑(특정 식재료의 가격 변동 내역을 조회할 때 사용)
    @Builder.Default // 해당 어노테이션이 없으면 빌더 패턴으로 객체를 생성할 때 해당 리스트가 빈 배열이 아니라 null로 덮어씌워짐 -> add 시 NullPointerEx
    @OneToMany(mappedBy = "ingredient", cascade = CascadeType.ALL)
    private List<IngredientPrice> priceHistories = new ArrayList<>();
}
