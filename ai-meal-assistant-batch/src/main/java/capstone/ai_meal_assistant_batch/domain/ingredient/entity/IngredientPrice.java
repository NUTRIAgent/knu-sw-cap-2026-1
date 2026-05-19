package capstone.ai_meal_assistant_batch.domain.ingredient.entity;

import capstone.ai_meal_assistant_batch.global.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;


/**
 * @Entity
 * - 기능: 통합 물가 레지스트리 (여러 API의 가격 데이터를 1g 단위로 통합하여 저장)
 */
@Entity
@Table(name = "ingredient_prices", indexes = {
//         날짜별로 가장 최근 가격을 빠르게 찾기 위한 인덱스
        @Index(name = "idx_price_date", columnList = "ingredient_id, base_date DESC")
})
@Getter
@Builder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PRIVATE)
// 물가 데이터 테이블
public class IngredientPrice extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ingredient_id", nullable = false)
    private Ingredient ingredient;

    // 계산용 표준 가격 (무조건 1g당 가격으로 환산해서 저장)
    @Column(nullable = false)
    private Double pricePerGram;

    // 데이터 출처 (어느 API에서 가져왔는지)
    // 예: "AGRI_MARKET" (농수산물), "CONSUMER_AGENCY" (참가격)
    @Column(nullable = false)
    private String sourceApi;

    // 디버깅 및 감사(Audit)용 원본 데이터 (필수 실무 팁)
    // 나중에 "왜 삼겹살 1g이 100원이지?"라고 에러가 났을 때 원본을 봐야 원인을 찾을 수 있음.
    private Integer originalPrice; // 원본 가격 (예: 5000)
    private String originalUnit;   // 원본 단위 (예: "100g", "1kg", "1팩")

    private String marketName;   // M_NAME: 남부골목시장
    private String marketType;  // M_TYPE_NAME: 전통시장

    @Column(nullable = false)
    private LocalDateTime baseDate; // P_DATE: 2026-03-24

    public void updatePrice(double pricePerGram, Integer originalPrice, String originalUnit) {
        this.pricePerGram = pricePerGram;
        this.originalPrice = originalPrice;
        this.originalUnit = originalUnit;
    }
}
