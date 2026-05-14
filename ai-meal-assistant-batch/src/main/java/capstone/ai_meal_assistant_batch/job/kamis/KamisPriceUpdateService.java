package capstone.ai_meal_assistant_batch.job.kamis;

import java.time.LocalDateTime;

import org.springframework.transaction.annotation.Transactional;
import org.springframework.stereotype.Service;

import capstone.ai_meal_assistant_batch.domain.ingredient.entity.Ingredient;
import capstone.ai_meal_assistant_batch.domain.ingredient.entity.IngredientPrice;
import capstone.ai_meal_assistant_batch.domain.ingredient.repository.IngredientPriceRepository;
import capstone.ai_meal_assistant_batch.domain.ingredient.repository.IngredientRepository;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class KamisPriceUpdateService {

	private static final String SOURCE_API = "KAMIS";

	private final IngredientRepository ingredientRepository;
	private final IngredientPriceRepository ingredientPriceRepository;

	/**
	 * TODO: KAMIS API 연동 후 구현
	 * - fetch -> parse/normalize -> upsert
	 * - 멱등성: (ingredient_id, price_date, market, unit 등) 유니크 키 기반 upsert 권장
	 */
	@Transactional
	public KamisPriceUpdateResult updateTodayPrices() {
		/*
		 * 지금은 외부 API 연동 전이라 샘플 1건을 upsert만 해두는 형태로 구현해둡니다.
		 * - 운영에서는 fetch 한 리스트를 돌면서 upsertPrice(...)를 호출하면 됩니다.
		 */
		int totalFetched = 1;
		UpsertOutcome outcome = upsertPrice(
				"양파",
				120.0 / 1000.0, // 1000g 120원 가정 -> 1g당 0.12원
				5000,
				"1kg",
				"남부골목시장",
				"전통시장",
				LocalDateTime.now().withHour(0).withMinute(0).withSecond(0).withNano(0));

		return new KamisPriceUpdateResult(
				totalFetched,
				outcome == UpsertOutcome.INSERTED ? 1 : 0,
				outcome == UpsertOutcome.UPDATED ? 1 : 0,
				outcome == UpsertOutcome.SKIPPED ? 1 : 0);
	}

	private enum UpsertOutcome {
		INSERTED, UPDATED, SKIPPED
	}

	private UpsertOutcome upsertPrice(
			String ingredientName,
			double pricePerGram,
			Integer originalPrice,
			String originalUnit,
			String marketName,
			String marketType,
			LocalDateTime baseDate) {
		Ingredient ingredient = ingredientRepository.findByName(ingredientName)
				.orElseGet(() -> ingredientRepository.save(Ingredient.builder().name(ingredientName).build()));

		var existing = ingredientPriceRepository
				.findByIngredientIdAndSourceApiAndMarketNameAndMarketTypeAndOriginalUnitAndBaseDate(
					ingredient.getId(),
					SOURCE_API,
					marketName,
					marketType,
					originalUnit,
					baseDate);

		if (existing.isEmpty()) {
			ingredientPriceRepository.save(IngredientPrice.builder()
					.ingredient(ingredient)
					.pricePerGram(pricePerGram)
					.sourceApi(SOURCE_API)
					.originalPrice(originalPrice)
					.originalUnit(originalUnit)
					.marketName(marketName)
					.marketType(marketType)
					.baseDate(baseDate)
					.build());
			return UpsertOutcome.INSERTED;
		}

		IngredientPrice old = existing.get();
		// 변경 없으면 skip
		if (old.getPricePerGram() != null && Double.compare(old.getPricePerGram(), pricePerGram) == 0) {
			return UpsertOutcome.SKIPPED;
		}

		old.updatePrice(pricePerGram, originalPrice, originalUnit);
		ingredientPriceRepository.save(old);
		return UpsertOutcome.UPDATED;
	}
}
