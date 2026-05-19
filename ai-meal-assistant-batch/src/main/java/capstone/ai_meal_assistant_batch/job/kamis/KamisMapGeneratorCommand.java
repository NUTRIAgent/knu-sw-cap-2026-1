package capstone.ai_meal_assistant_batch.job.kamis;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Component;

import com.fasterxml.jackson.databind.ObjectMapper;

import capstone.ai_meal_assistant_batch.domain.ingredient.repository.IngredientRepository;
import capstone.ai_meal_assistant_batch.global.log.BatchLog;
import lombok.RequiredArgsConstructor;

/**
 * DB의 ingredients와 KAMIS dailySalesList 전체 품목을 비교해서
 * 자동 매핑(JSON)을 생성한다.
 *
 * 실행:
 *  -Dspring-boot.run.arguments="--batch.kamis.generate-map=true"
 */
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "batch.kamis", name = "generate-map", havingValue = "true")
public class KamisMapGeneratorCommand implements ApplicationRunner {

	private static final String JOB_NAME = "kamisGenerateIngredientMap";

	private final IngredientRepository ingredientRepository;
	private final KamisNaturePriceListClient client;
	private final KamisNaturePriceListXmlParser parser;
	private final ObjectMapper objectMapper;
	private final ApplicationContext applicationContext;

	@Override
	public void run(ApplicationArguments args) throws Exception {
		Instant start = BatchLog.start(JOB_NAME);
		try {
			// 1) DB 재료명
			List<String> ingredientNames = ingredientRepository.findAll().stream()
					.map(i -> i.getName())
					.filter(Objects::nonNull)
					.map(String::trim)
					.filter(s -> !s.isBlank())
					.distinct()
					.sorted()
					.toList();

			// 2) KAMIS 전체 품목(이미 지금 코드에서 단건 호출로 전체 items 확보 가능)
			String xml = client.fetchXml(Map.of());
			KamisNaturePriceListXmlParser.ParsedKamisResponse parsed = parser.parse(xml);
			if (parsed.errorCode() != null && !"000".equals(parsed.errorCode())) {
				throw new IllegalStateException("KAMIS responded error_code=" + parsed.errorCode() + " msg=" + parsed.errorMsg());
			}

			// 가격 정보는 중복이 많아서, "품목코드(productno)별 대표 품목명"을 뽑고,
			// 다(多)대1 매핑이 아닌 "이름 후보" 생성을 위해 item_name들을 유니크 리스트로 만든다.
			Map<String, String> productNoToName = new LinkedHashMap<>();
			for (var item : parsed.items()) {
				if (item.productno() == null || item.productno().isBlank()) {
					continue;
				}
				String name = item.itemName();
				if (name == null || name.isBlank()) {
					continue;
				}
				productNoToName.putIfAbsent(item.productno().trim(), name.trim());
			}
			List<KamisItem> kamisItems = productNoToName.entrySet().stream()
					.map(e -> new KamisItem(e.getKey(), e.getValue()))
					.toList();
			List<String> kamisNames = kamisItems.stream().map(KamisItem::kamisName).distinct().toList();

			// 3) 매칭: ingredientName -> top 후보 5개
			List<GeneratedMapping> generated = new ArrayList<>(ingredientNames.size());
			for (String ing : ingredientNames) {
				KamisNameMatcher.MatchResult mr = KamisNameMatcher.bestMatch(ing, kamisNames, 5);
				List<Candidate> top = mr.topCandidates().stream()
						.map(s -> {
							String bestName = s.candidate();
							List<String> productNos = kamisItems.stream()
									.filter(ki -> ki.kamisName().equals(bestName))
									.map(KamisItem::productNo)
									.sorted()
									.toList();
							return new Candidate(bestName, s.score(), productNos);
						})
						.toList();
				generated.add(new GeneratedMapping(ing, top));
			}

			GeneratedFile out = new GeneratedFile(
					Instant.now().toString(),
					ingredientNames.size(),
					kamisItems.size(),
					generated
			);

			Path outPath = Path.of("build", "kamis-ingredient-map.generated.json");
			Files.createDirectories(outPath.getParent());
			String json = objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(out);
			Files.writeString(outPath, json + "\n", StandardCharsets.UTF_8);

			System.out.println("[KAMIS][MAP_GENERATOR] saved=" + outPath.toAbsolutePath());
			System.out.println("[KAMIS][MAP_GENERATOR] ingredients=" + ingredientNames.size() + " kamisItems=" + kamisItems.size());

			BatchLog.success(JOB_NAME, start, Map.of(
					"out", outPath.toString(),
					"ingredientCount", ingredientNames.size(),
					"kamisUniqueItems", kamisItems.size()));

			int exitCode = SpringApplication.exit(applicationContext, () -> 0);
			System.exit(exitCode);
		} catch (Exception e) {
			BatchLog.fail(JOB_NAME, start, e);
			throw e;
		}
	}

	/** KAMIS 품목코드 + 대표 품목명 */
	record KamisItem(String productNo, String kamisName) {
	}

	/** 생성 파일 루트 */
	record GeneratedFile(
			String generatedAt,
			int ingredientCount,
			int kamisUniqueItemCount,
			List<GeneratedMapping> mappings) {
	}

	record GeneratedMapping(
			String ingredientName,
			List<Candidate> candidates) {
	}

	record Candidate(
			String kamisName,
			double score,
			List<String> productNos) {
	}
}
