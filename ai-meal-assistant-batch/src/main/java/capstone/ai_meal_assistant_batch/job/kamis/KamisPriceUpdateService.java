package capstone.ai_meal_assistant_batch.job.kamis;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import capstone.ai_meal_assistant_batch.domain.ingredient.entity.Ingredient;
import capstone.ai_meal_assistant_batch.domain.ingredient.entity.IngredientKamisMapping;
import capstone.ai_meal_assistant_batch.domain.ingredient.entity.IngredientPrice;
import capstone.ai_meal_assistant_batch.domain.ingredient.repository.IngredientKamisMappingRepository;
import capstone.ai_meal_assistant_batch.domain.ingredient.repository.IngredientPriceRepository;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class KamisPriceUpdateService {

    private static final String SOURCE_API = "KAMIS_DAILY_SALES";

    private final IngredientPriceRepository ingredientPriceRepository;
    private final IngredientKamisMappingRepository mappingRepository;
    private final KamisNaturePriceListClient client;
    private final KamisNaturePriceListXmlParser parser;

    @Transactional
    public KamisPriceUpdateResult updateTodayPrices() {
        return updateTodayPrices(false, false);
    }

    @Transactional
    public KamisPriceUpdateResult updateTodayPricesForced() {
        return updateTodayPrices(false, true);
    }

    @Transactional
    public KamisPriceUpdateResult updateTodayPrices(boolean dryRun, boolean forceUpdate) {
        int totalFetched = 0;
        int inserted = 0;
        int updated = 0;
        int skipped = 0;

        String xml = client.fetchXml(new HashMap<>());
        KamisNaturePriceListXmlParser.ParsedKamisResponse parsed;
        try {
            parsed = parser.parse(xml);
        } catch (Exception parseEx) {
            System.out.println("[KAMIS][ERROR] XML Parsing Failed: " + parseEx.getMessage());
            throw parseEx;
        }

        if (parsed.errorCode() != null && !"000".equals(parsed.errorCode())) {
            System.out.println("[KAMIS][ERROR] API error_code=" + parsed.errorCode() + ", msg=" + parsed.errorMsg());
            return new KamisPriceUpdateResult(0, 0, 0, 0);
        }

        totalFetched = parsed.items().size();

        Map<String, List<KamisNaturePriceListXmlParser.KamisDailySalesItem>> itemsByCode = parsed.items().stream()
                .filter(item -> item.productno() != null)
                .collect(Collectors.groupingBy(KamisNaturePriceListXmlParser.KamisDailySalesItem::productno));

        List<IngredientKamisMapping> mappings = mappingRepository.findAllByConfirmedTrue();

        for (IngredientKamisMapping mapping : mappings) {
            List<KamisNaturePriceListXmlParser.KamisDailySalesItem> matchedItems =
                    itemsByCode.get(mapping.getKamisItemCode());

            if (matchedItems == null || matchedItems.isEmpty()) {
                skipped++;
                continue;
            }

            for (var item : matchedItems) {
                NormalizedRow row = normalize(mapping.getIngredient(), item);
                if (row == null) {
                    skipped++;
                    continue;
                }

                if (dryRun) {
                    skipped++;
                    continue;
                }

                UpsertOutcome outcome = upsertPrice(
                        row.ingredient(),
                        row.pricePerGram(),
                        row.originalPrice(),
                        row.originalUnit(),
                        row.marketName(),
                        row.marketType(),
                        row.baseDate(),
                        forceUpdate);

                switch (outcome) {
                    case INSERTED -> inserted++;
                    case UPDATED -> updated++;
                    case SKIPPED -> skipped++;
                }
            }
        }

        return new KamisPriceUpdateResult(totalFetched, inserted, updated, skipped);
    }

    private NormalizedRow normalize(Ingredient ingredient, KamisNaturePriceListXmlParser.KamisDailySalesItem item) {
        Integer originalPrice = parsePrice(item.dpr1());
        if (originalPrice == null) return null;

        String originalUnit = item.unit();
        Double pricePerGram = convertToPricePerGram(originalPrice, originalUnit);
        if (pricePerGram == null) return null;

        LocalDateTime baseDate = parseKamisDate(item.lastestDay());
        String marketName = item.productClsName();
        String marketType = item.categoryName();

        return new NormalizedRow(ingredient, pricePerGram, originalPrice, originalUnit, marketName, marketType, baseDate);
    }

    private LocalDateTime parseKamisDate(String day1) {
        if (day1 == null || day1.isBlank()) return LocalDateTime.now();
        day1 = day1.trim();
        try {
            if (day1.length() == 10) {
                return LocalDate.parse(day1, DateTimeFormatter.ofPattern("yyyy-MM-dd")).atStartOfDay();
            }
            if (day1.length() == 5 && day1.contains("/")) {
                int year = LocalDate.now().getYear();
                return LocalDate.parse(year + "/" + day1, DateTimeFormatter.ofPattern("yyyy/MM/dd")).atStartOfDay();
            }
        } catch (Exception e) {
            // fallback
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
            Ingredient ingredient,
            double pricePerGram,
            Integer originalPrice,
            String originalUnit,
            String marketName,
            String marketType,
            LocalDateTime baseDate) {}

    private enum UpsertOutcome { INSERTED, UPDATED, SKIPPED }

    private UpsertOutcome upsertPrice(
            Ingredient ingredient,
            double pricePerGram,
            Integer originalPrice,
            String originalUnit,
            String marketName,
            String marketType,
            LocalDateTime baseDate,
            boolean forceUpdate) {

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
        if (!forceUpdate && old.getPricePerGram() != null && Double.compare(old.getPricePerGram(), pricePerGram) == 0) {
            return UpsertOutcome.SKIPPED;
        }

        old.updatePrice(pricePerGram, originalPrice, originalUnit);
        ingredientPriceRepository.save(old);
        return UpsertOutcome.UPDATED;
    }
}
