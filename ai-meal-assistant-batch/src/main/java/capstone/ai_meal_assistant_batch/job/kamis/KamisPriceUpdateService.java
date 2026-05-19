package capstone.ai_meal_assistant_batch.job.kamis;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

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

	private static final String SOURCE_API = "KAMIS_DAILY_SALES";

	private final IngredientRepository ingredientRepository;
	private final IngredientPriceRepository ingredientPriceRepository;
	private final KamisNaturePriceListClient client;
	private final KamisNaturePriceListXmlParser parser;
	private final KamisIngredientMapLoader mapLoader;

	@Transactional
	public KamisPriceUpdateResult updateTodayPrices() {
		return updateTodayPrices(false);
	}

	@Transactional
	public KamisPriceUpdateResult updateTodayPrices(boolean dryRun) {
		int totalFetched = 0;
		int inserted = 0;
		int updated = 0;
		int skipped = 0;

		// 1. 전체 데이터 단건 호출 (파라미터 불필요)
		Map<String, String> emptyParams = new HashMap<>();
		String xml = client.fetchXml(emptyParams);
		KamisNaturePriceListXmlParser.ParsedKamisResponse parsed;
		
		try {
			parsed = parser.parse(xml);
		} catch (Exception parseEx) {
			System.out.println("[KAMIS][ERROR] XML Parsing Failed: " + parseEx.getMessage());
			throw parseEx;
		}

		if (parsed.errorCode() != null && !"000".equals(parsed.errorCode())) {
			System.out.println("[KAMIS][ERROR] API responded with error_code=" + parsed.errorCode() + ", msg=" + parsed.errorMsg());
			return new KamisPriceUpdateResult(0, 0, 0, 0);
		}

		totalFetched = parsed.items().size();

		// 2. 파싱된 데이터를 productno(품목코드) 기준으로 그룹화
		Map<String, List<KamisNaturePriceListXmlParser.KamisDailySalesItem>> itemsByCode = parsed.items().stream()
				.filter(item -> item.productno() != null)
				.collect(Collectors.groupingBy(KamisNaturePriceListXmlParser.KamisDailySalesItem::productno));

		// 🚀 [여기부터 추가] KAMIS가 실제로 내려준 223개의 품목코드와 이름을 콘솔에 찍어봅니다.
		System.out.println("=== [KAMIS 품목 코드 목록 (" + totalFetched + "개)] ===");
		itemsByCode.forEach((code, list) -> {
			System.out.println("코드: " + code + ", 품목명: " + list.get(0).itemName() + ", 가격: " + list.get(0).dpr1());
		});
		System.out.println("==============================================");

		var entries = mapLoader.load();

		// 3. 내부 재료 리스트를 순회하며 그룹화된 데이터와 매핑
		for (var entry : entries) {
			if (entry.kamis() == null || entry.kamis().itemCode() == null) {
				skipped++;
				continue;
			}
			
			String targetCode = entry.kamis().itemCode();
			List<KamisNaturePriceListXmlParser.KamisDailySalesItem> matchedItems = itemsByCode.get(targetCode);

			if (matchedItems == null || matchedItems.isEmpty()) {
				skipped++;
				continue;
			}

			// 하나의 품목코드에 도매/소매 데이터가 모두 있을 수 있으므로 전부 순회
			for (var item : matchedItems) {
				NormalizedRow row = normalize(entry.ingredientName(), item);
				if (row == null) {
					skipped++;
					continue;
				}

				if (dryRun) {
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
		}

		return new KamisPriceUpdateResult(totalFetched, inserted, updated, skipped);
	}

	private NormalizedRow normalize(String ingredientName, KamisNaturePriceListXmlParser.KamisDailySalesItem item) {
		Integer originalPrice = parsePrice(item.dpr1());
		if (originalPrice == null) return null;

		String originalUnit = item.unit();
		Double pricePerGram = convertToPricePerGram(originalPrice, originalUnit);
		if (pricePerGram == null) return null;

		LocalDateTime baseDate = parseKamisDate(item.day1());

		// 도매/소매를 marketName으로, 부류명(채소, 과일 등)을 marketType으로 사용
		String marketName = item.productClsName(); 
		String marketType = item.categoryName(); 
		
		return new NormalizedRow(ingredientName, pricePerGram, originalPrice, originalUnit, marketName, marketType, baseDate);
	}

	private LocalDateTime parseKamisDate(String day1) {
		if (day1 == null || day1.isBlank()) return LocalDateTime.now();
		day1 = day1.trim();
		try {
			// YYYY-MM-DD 형식으로 올 경우
			if (day1.length() == 10) {
				return LocalDate.parse(day1, DateTimeFormatter.ofPattern("yyyy-MM-dd")).atStartOfDay();
			}
			// MM/DD 형식으로 올 경우 (KAMIS 기본 형식)
			if (day1.length() == 5 && day1.contains("/")) {
				int year = LocalDate.now().getYear();
				return LocalDate.parse(year + "/" + day1, DateTimeFormatter.ofPattern("yyyy/MM/dd")).atStartOfDay();
			}
		} catch (Exception e) {
			// 파싱 실패 시 현재 시간 Fallback
		}
		return LocalDateTime.now();
	}

	private static Integer parsePrice(String raw) {
		if (raw == null) return null;
		String digits = raw.replaceAll("[^0-9]", "");
		if (digits.isBlank()) return null;
		try {
			return Integer.parseInt(digits);
		} catch (NumberFormatException e) {
			return null;
		}
	}

	private static Double convertToPricePerGram(Integer price, String unit) {
		if (price == null || unit == null || unit.isBlank()) return null;
		String u = unit.trim().toLowerCase(Locale.KOREA);
		
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
			LocalDateTime baseDate) {}

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
		if (old.getPricePerGram() != null && Double.compare(old.getPricePerGram(), pricePerGram) == 0) {
			return UpsertOutcome.SKIPPED;
		}

		old.updatePrice(pricePerGram, originalPrice, originalUnit);
		ingredientPriceRepository.save(old);
		return UpsertOutcome.UPDATED;
	}
}