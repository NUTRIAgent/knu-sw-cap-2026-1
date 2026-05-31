package capstone.ai_meal_assistant_batch.job.kamis;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Locale;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import capstone.ai_meal_assistant_batch.domain.ingredient.entity.IngredientKamisPrice;
import capstone.ai_meal_assistant_batch.domain.ingredient.repository.IngredientKamisPriceRepository;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class KamisPriceUpdateService {

    private static final String SOURCE_API = "KAMIS_DAILY_SALES";

    private final IngredientKamisPriceRepository ingredientKamisPriceRepository;
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

        for (var item : parsed.items()) {
            NormalizedRow row = normalize(item);
            if (row == null) {
                skipped++;
                continue;
            }

            if (dryRun) {
                skipped++;
                continue;
            }

            UpsertOutcome outcome = upsertPrice(row, forceUpdate);
            switch (outcome) {
                case INSERTED -> inserted++;
                case UPDATED -> updated++;
                case SKIPPED -> skipped++;
            }
        }

        return new KamisPriceUpdateResult(totalFetched, inserted, updated, skipped);
    }

    private NormalizedRow normalize(KamisNaturePriceListXmlParser.KamisDailySalesItem item) {
        Integer originalPrice = parsePrice(item.dpr1());
        if (originalPrice == null) return null;

        String originalUnit = item.unit();
        Double pricePerGram = convertToPricePerGram(originalPrice, originalUnit);
        if (pricePerGram == null) return null;

        String kamisItemCode = item.productno();
        String kamisItemName = (item.itemName() != null && !item.itemName().isBlank())
                ? item.itemName()
                : kamisItemCode;
        LocalDateTime baseDate = parseKamisDate(item.lastestDay());
        String marketName = item.productClsName();
        String marketType = item.categoryName();
        Integer prevDayPrice = parsePrice(item.dpr2());
        Integer prevWeekPrice = parsePrice(item.dpr3());
        Integer prevMonthPrice = parsePrice(item.dpr5());

        return new NormalizedRow(kamisItemCode, kamisItemName, pricePerGram, originalPrice,
                originalUnit, marketName, marketType, baseDate, prevDayPrice, prevWeekPrice, prevMonthPrice);
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
            String kamisItemCode,
            String kamisItemName,
            double pricePerGram,
            Integer originalPrice,
            String originalUnit,
            String marketName,
            String marketType,
            LocalDateTime baseDate,
            Integer prevDayPrice,
            Integer prevWeekPrice,
            Integer prevMonthPrice) {}

    private enum UpsertOutcome { INSERTED, UPDATED, SKIPPED }

    private UpsertOutcome upsertPrice(NormalizedRow row, boolean forceUpdate) {
        var existing = ingredientKamisPriceRepository
                .findByKamisItemCodeAndMarketNameAndMarketTypeAndOriginalUnitAndBaseDate(
                        row.kamisItemCode(),
                        row.marketName(),
                        row.marketType(),
                        row.originalUnit(),
                        row.baseDate());

        if (existing.isEmpty()) {
            ingredientKamisPriceRepository.save(IngredientKamisPrice.builder()
                    .kamisItemCode(row.kamisItemCode())
                    .kamisItemName(row.kamisItemName())
                    .pricePerGram(row.pricePerGram())
                    .sourceApi(SOURCE_API)
                    .originalPrice(row.originalPrice())
                    .originalUnit(row.originalUnit())
                    .marketName(row.marketName())
                    .marketType(row.marketType())
                    .baseDate(row.baseDate())
                    .prevDayPrice(row.prevDayPrice())
                    .prevWeekPrice(row.prevWeekPrice())
                    .prevMonthPrice(row.prevMonthPrice())
                    .build());
            return UpsertOutcome.INSERTED;
        }

        IngredientKamisPrice old = existing.get();
        if (!forceUpdate && old.getPricePerGram() != null
                && Double.compare(old.getPricePerGram(), row.pricePerGram()) == 0) {
            return UpsertOutcome.SKIPPED;
        }

        old.updatePrice(row.pricePerGram(), row.originalPrice(), row.originalUnit(),
                row.prevDayPrice(), row.prevWeekPrice(), row.prevMonthPrice());
        ingredientKamisPriceRepository.save(old);
        return UpsertOutcome.UPDATED;
    }
}
