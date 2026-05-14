package capstone.ai_meal_assistant_batch.domain.ingredient.entity;

import java.time.LocalDateTime;

import capstone.ai_meal_assistant_batch.global.entity.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 통합 물가 레지스트리(여러 API의 가격 데이터를 1g 단위로 통합하여 저장)
 */
@Entity
@Table(name = "ingredient_prices", indexes = {
		@Index(name = "idx_price_date", columnList = "ingredient_id, base_date DESC")
})
@Getter
@Builder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PRIVATE)
public class IngredientPrice extends BaseEntity {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "ingredient_id", nullable = false)
	private Ingredient ingredient;

	@Column(nullable = false)
	private Double pricePerGram;

	@Column(nullable = false)
	private String sourceApi;

	private Integer originalPrice;
	private String originalUnit;

	private String marketName;
	private String marketType;

	@Column(nullable = false)
	private LocalDateTime baseDate;

	public void updatePrice(double pricePerGram, Integer originalPrice, String originalUnit) {
		this.pricePerGram = pricePerGram;
		this.originalPrice = originalPrice;
		this.originalUnit = originalUnit;
	}
}
