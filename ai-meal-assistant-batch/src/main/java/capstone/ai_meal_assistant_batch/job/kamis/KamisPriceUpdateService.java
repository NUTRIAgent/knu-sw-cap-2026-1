package capstone.ai_meal_assistant_batch.job.kamis;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

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
	private static final DateTimeFormatter REGDAY_FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.S", Locale.KOREA);

	private final IngredientRepository ingredientRepository;
	private final IngredientPriceRepository ingredientPriceRepository;
	private final KamisNaturePriceListClient client;
	private final KamisNaturePriceListXmlParser parser;

	/**
	 * TODO: KAMIS API 연동 후 구현
	 * - fetch -> parse/normalize -> upsert
	 * - 멱등성: (ingredient_id, price_date, market, unit 등) 유니크 키 기반 upsert 권장
	 */
	@Transactional
	public KamisPriceUpdateResult updateTodayPrices() {
		return updateTodayPrices(false);
	}

	/**
	 * @param dryRun true면 DB upsert를 수행하지 않고, 파싱/정규화/집계만 수행합니다.
	 */
	@Transactional
	public KamisPriceUpdateResult updateTodayPrices(boolean dryRun) {
		// TODO: 카테고리/품목/품종/등급/지역 코드는 추후 운영 정책에 맞춰 확장
		// 여기선 파이프라인(호출 -> 파싱 -> 정규화 -> upsert) 연결을 먼저 완성
		Map<String, String> params = defaultRequestParams();
		String xml = client.fetchXml(params);
		var parsed = parser.parse(xml);
		if (parsed.errorCode() != null && !"000".equals(parsed.errorCode())) {
			throw new IllegalStateException("KAMIS API error_code=" + parsed.errorCode());
		}

		int inserted = 0;
		int updated = 0;
		int skipped = 0;

		for (var item : parsed.items()) {
			NormalizedRow row = normalize(item);
			if (row == null) {
				skipped++;
				continue;
			}

			if (dryRun) {
				// DB 저장 없이 파싱/정규화 성공 건 집계만
				skipped++;
				continue;
			}

			UpsertOutcome outcome = upsertPrice(
					row.ingredientName(),
					row.pricePerGram(),
					row.originalPrice(),
					row.originalUnit(),
					row.marketName(),
					row.marketType(),
					row.baseDate());

			switch (outcome) {
				case INSERTED -> inserted++;
				case UPDATED -> updated++;
				case SKIPPED -> skipped++;
			}
		}

		return new KamisPriceUpdateResult(parsed.items().size(), inserted, updated, skipped);
	}

	private Map<String, String> defaultRequestParams() {
		LocalDate today = LocalDate.now();
		Map<String, String> p = new HashMap<>();
		// 최소 파이프라인 검증용 값(실제 값은 운영정책/설정으로 대체 권장)
		p.put("p_regday", today.toString());
		p.put("p_itemcategorycode", "100");
		p.put("p_itemcode", "111");
		p.put("p_kindcode", "01");
		p.put("p_productrankcode", "07");
		p.put("p_countrycode", "1101");
		p.put("p_convert_kg_yn", "Y");
		return p;
	}

	private NormalizedRow normalize(KamisNaturePriceListXmlParser.KamisNaturePriceItem item) {
		Integer originalPrice = parsePrice(item.price());
		if (originalPrice == null) {
			return null;
		}

		String originalUnit = item.unit();
		Double pricePerGram = convertToPricePerGram(originalPrice, originalUnit);
		if (pricePerGram == null) {
			return null;
		}

		LocalDateTime baseDate;
		try {
			baseDate = LocalDateTime.parse(item.regday(), REGDAY_FMT);
		} catch (Exception e) {
			return null;
		}

		// 지금 API는 재료명(itemname)을 주지 않으므로, 현재는 itemcode를 이름으로 매핑하는 전략이 필요함.
		// 우선 MVP로 itemcode 기반 임시 이름을 생성(운영에서는 code->name 테이블/매핑 필요)
		String ingredientName = "KAMIS_ITEM_" + (item.seqnum() == null ? "UNKNOWN" : item.seqnum());

		String marketName = item.marketname();
		String marketType = item.countyname();
		return new NormalizedRow(ingredientName, pricePerGram, originalPrice, originalUnit, marketName, marketType, baseDate);
	}

	private static Integer parsePrice(String raw) {
		if (raw == null) {
			return null;
		}
		String digits = raw.replaceAll("[^0-9]", "");
		if (digits.isBlank()) {
			return null;
		}
		try {
			return Integer.parseInt(digits);
		} catch (NumberFormatException e) {
			return null;
		}
	}

	private static Double convertToPricePerGram(Integer price, String unit) {
		if (price == null || unit == null || unit.isBlank()) {
			return null;
		}
		String u = unit.trim().toLowerCase(Locale.KOREA);
		// 현 응답 샘플: 1kg
		if (u.endsWith("kg")) {
			String n = u.replace("kg", "").trim();
			double kg = n.isBlank() ? 1.0 : Double.parseDouble(n);
			return price / (kg * 1000.0);
		}
		if (u.endsWith("g")) {
			String n = u.replace("g", "").trim();
			double g = n.isBlank() ? 1.0 : Double.parseDouble(n);
			return price / g;
		}
		return null;
	}

	private record NormalizedRow(
			String ingredientName,
			double pricePerGram,
			Integer originalPrice,
			String originalUnit,
			String marketName,
			String marketType,
			LocalDateTime baseDate) {
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
				.orElseGet(() -> {
					Ingredient saved = ingredientRepository.save(Ingredient.builder().name(ingredientName).build());
					return saved;
				});

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
