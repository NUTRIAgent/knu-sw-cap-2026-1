package capstone.ai_meal_assistant_batch.job.kamis;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Component;

import capstone.ai_meal_assistant_batch.domain.ingredient.entity.Ingredient;
import capstone.ai_meal_assistant_batch.domain.ingredient.entity.IngredientKamisMapping;
import capstone.ai_meal_assistant_batch.domain.ingredient.repository.IngredientKamisMappingRepository;
import capstone.ai_meal_assistant_batch.domain.ingredient.repository.IngredientRepository;
import capstone.ai_meal_assistant_batch.global.log.BatchLog;
import lombok.RequiredArgsConstructor;

/**
 * DB의 ingredients와 KAMIS dailySalesList 전체 품목을 비교해서
 * 재료당 상위 3개 후보를 ingredient_kamis_mappings 테이블에 confirmed=false로 저장한다.
 *
 * 실행: --batch.kamis.generate-map=true
 */
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "batch.kamis", name = "generate-map", havingValue = "true")
public class KamisMapGeneratorCommand implements ApplicationRunner {

    private static final String JOB_NAME = "kamisGenerateIngredientMap";
    private static final int TOP_K = 3;

    private final IngredientRepository ingredientRepository;
    private final IngredientKamisMappingRepository mappingRepository;
    private final KamisNaturePriceListClient client;
    private final KamisNaturePriceListXmlParser parser;
    private final ApplicationContext applicationContext;

    @Override
    public void run(ApplicationArguments args) throws Exception {
        Instant start = BatchLog.start(JOB_NAME);
        try {
            // 1) DB 재료 목록
            List<Ingredient> ingredients = ingredientRepository.findAll().stream()
                    .filter(i -> i.getName() != null && !i.getName().isBlank())
                    .sorted((a, b) -> a.getName().compareTo(b.getName()))
                    .toList();

            // 2) KAMIS 전체 품목 조회
            String xml = client.fetchXml(Map.of());
            KamisNaturePriceListXmlParser.ParsedKamisResponse parsed = parser.parse(xml);
            if (parsed.errorCode() != null && !"000".equals(parsed.errorCode())) {
                throw new IllegalStateException("KAMIS error_code=" + parsed.errorCode() + " msg=" + parsed.errorMsg());
            }

            // productno별 대표 품목명 추출 (중복 제거)
            Map<String, String> productNoToName = new LinkedHashMap<>();
            for (var item : parsed.items()) {
                if (item.productno() == null || item.productno().isBlank()) continue;
                if (item.itemName() == null || item.itemName().isBlank()) continue;
                productNoToName.putIfAbsent(item.productno().trim(), item.itemName().trim());
            }
            List<KamisItem> kamisItems = productNoToName.entrySet().stream()
                    .map(e -> new KamisItem(e.getKey(), e.getValue()))
                    .toList();
            List<String> kamisNames = kamisItems.stream().map(KamisItem::kamisName).distinct().toList();

            // 3) 재료별 상위 3개 후보 매칭 후 DB 저장
            List<IngredientKamisMapping> toSave = new ArrayList<>();
            int skippedConfirmed = 0;
            int skippedDuplicate = 0;

            for (Ingredient ingredient : ingredients) {
                // confirmed=true 매핑이 이미 있는 재료는 건드리지 않음
                if (mappingRepository.existsByIngredientIdAndConfirmedTrue(ingredient.getId())) {
                    skippedConfirmed++;
                    continue;
                }

                KamisNameMatcher.MatchResult mr = KamisNameMatcher.bestMatch(ingredient.getName(), kamisNames, TOP_K);

                for (KamisNameMatcher.Scored s : mr.topCandidates()) {
                    List<String> productNos = kamisItems.stream()
                            .filter(ki -> ki.kamisName().equals(s.candidate()))
                            .map(KamisItem::productNo)
                            .sorted()
                            .toList();
                    if (productNos.isEmpty()) continue;

                    String itemCode = productNos.get(0);

                    // 동일 재료 + 동일 코드 조합이 이미 있으면 스킵 (멱등성)
                    if (mappingRepository.existsByIngredientIdAndKamisItemCode(ingredient.getId(), itemCode)) {
                        skippedDuplicate++;
                        continue;
                    }

                    toSave.add(IngredientKamisMapping.builder()
                            .ingredient(ingredient)
                            .ingredientName(ingredient.getName())
                            .kamisItemCode(itemCode)
                            .kamisItemName(s.candidate())
                            .autoScore(s.score())
                            .build());
                }
            }

            mappingRepository.saveAll(toSave);

            System.out.println("[KAMIS][MAP_GENERATOR] saved=" + toSave.size()
                    + " skippedConfirmed=" + skippedConfirmed
                    + " skippedDuplicate=" + skippedDuplicate
                    + " ingredients=" + ingredients.size()
                    + " kamisItems=" + kamisItems.size());

            BatchLog.success(JOB_NAME, start, Map.of(
                    "saved", toSave.size(),
                    "ingredientCount", ingredients.size(),
                    "kamisUniqueItems", kamisItems.size()));

            int exitCode = SpringApplication.exit(applicationContext, () -> 0);
            System.exit(exitCode);
        } catch (Exception e) {
            BatchLog.fail(JOB_NAME, start, e);
            throw e;
        }
    }

    record KamisItem(String productNo, String kamisName) {}
}
