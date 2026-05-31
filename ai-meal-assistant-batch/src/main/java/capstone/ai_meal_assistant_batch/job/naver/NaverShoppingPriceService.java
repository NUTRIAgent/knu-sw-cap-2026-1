package capstone.ai_meal_assistant_batch.job.naver;

import capstone.ai_meal_assistant_batch.domain.ingredient.entity.Ingredient;
import capstone.ai_meal_assistant_batch.domain.ingredient.entity.IngredientPrice;
import capstone.ai_meal_assistant_batch.domain.ingredient.repository.IngredientPriceRepository;
import capstone.ai_meal_assistant_batch.domain.ingredient.repository.IngredientRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class NaverShoppingPriceService {

    private static final String SOURCE_API = "NAVER_SHOPPING";
    // kg, g, L, ml 모두 지원 (액체류 커버)
    private static final Pattern WEIGHT_PATTERN =
            Pattern.compile("([0-9]+(?:[.,][0-9]+)?)\\s*(kg|ml|g|l)", Pattern.CASE_INSENSITIVE);
    private static final double MAX_PRICE_PER_GRAM = 1000.0;
    private static final double MAX_WEIGHT_GRAMS = 30_000.0;

    private final IngredientRepository ingredientRepository;
    private final IngredientPriceRepository ingredientPriceRepository;
    private final NaverShoppingClient client;

    private record PriceData(double pricePerGram, int originalPrice, String originalUnit) {}

    @Transactional
    public NaverShoppingPriceResult updateAllPrices() {
        List<Ingredient> ingredients = ingredientRepository.findAll();
        int updated = 0;
        int skipped = 0;

        for (Ingredient ingredient : ingredients) {
            try {
                Optional<PriceData> priceData = fetchPriceData(ingredient.getName());
                if (priceData.isEmpty()) {
                    skipped++;
                    continue;
                }
                upsertPrice(ingredient, priceData.get());
                updated++;
                Thread.sleep(50);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            } catch (Exception e) {
                skipped++;
            }
        }

        return new NaverShoppingPriceResult(updated, skipped);
    }

    private Optional<PriceData> fetchPriceData(String ingredientName) {
        // 1차: 재료명 그대로 검색
        Optional<PriceData> result = parseFromItems(client.search(ingredientName));
        if (result.isPresent()) return result;

        // 2차: 파싱 실패 시 "재료명 1kg" 으로 재검색 (계란, 개수 단위 상품 대응)
        return parseFromItems(client.search(ingredientName + " 1kg"));
    }

    private Optional<PriceData> parseFromItems(List<NaverShoppingItem> items) {
        List<PriceData> prices = items.stream()
                .map(item -> calcPriceData(item.title(), item.lprice()))
                .filter(Optional::isPresent)
                .map(Optional::get)
                .filter(p -> p.pricePerGram() > 0 && p.pricePerGram() < MAX_PRICE_PER_GRAM)
                .sorted(Comparator.comparingDouble(PriceData::pricePerGram))
                .toList();

        if (prices.isEmpty()) return Optional.empty();
        return Optional.of(prices.get(prices.size() / 2));
    }

    private Optional<PriceData> calcPriceData(String rawTitle, String lpriceStr) {
        try {
            int lprice = Integer.parseInt(lpriceStr);
            if (lprice <= 0) return Optional.empty();

            String title = rawTitle.replaceAll("<[^>]+>", "");
            Matcher m = WEIGHT_PATTERN.matcher(title);
            while (m.find()) {
                String num = m.group(1).replace(",", "");
                double amount = Double.parseDouble(num);
                String unit = m.group(2).toLowerCase();
                double grams = toGrams(amount, unit);
                if (grams > 0 && grams <= MAX_WEIGHT_GRAMS) {
                    String originalUnit = formatUnit(amount, unit);
                    return Optional.of(new PriceData(lprice / grams, lprice, originalUnit));
                }
            }
        } catch (Exception ignored) {}
        return Optional.empty();
    }

    private static double toGrams(double amount, String unit) {
        return switch (unit) {
            case "kg" -> amount * 1000.0;
            case "l"  -> amount * 1000.0; // 1L ≈ 1000g (밀도 근사)
            case "ml" -> amount;           // 1ml ≈ 1g
            default   -> amount;           // g
        };
    }

    private static String formatUnit(double amount, String unit) {
        String num = amount == Math.floor(amount) ? String.valueOf((int) amount) : String.valueOf(amount);
        return switch (unit) {
            case "kg" -> num + "kg";
            case "l"  -> num + "L";
            case "ml" -> num + "ml";
            default   -> num + "g";
        };
    }

    private void upsertPrice(Ingredient ingredient, PriceData data) {
        LocalDateTime now = LocalDateTime.now();
        Optional<IngredientPrice> existing =
                ingredientPriceRepository.findTopByIngredientIdAndSourceApi(ingredient.getId(), SOURCE_API);

        if (existing.isPresent()) {
            existing.get().updateNaverPrice(data.pricePerGram(), data.originalPrice(), data.originalUnit(), now);
        } else {
            ingredientPriceRepository.save(IngredientPrice.builder()
                    .ingredient(ingredient)
                    .pricePerGram(data.pricePerGram())
                    .sourceApi(SOURCE_API)
                    .originalPrice(data.originalPrice())
                    .originalUnit(data.originalUnit())
                    .baseDate(now)
                    .lastSyncAt(now)
                    .build());
        }
    }
}
