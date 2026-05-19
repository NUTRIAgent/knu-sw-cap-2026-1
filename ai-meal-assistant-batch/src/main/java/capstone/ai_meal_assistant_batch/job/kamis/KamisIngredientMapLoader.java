package capstone.ai_meal_assistant_batch.job.kamis;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;

import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import com.fasterxml.jackson.databind.ObjectMapper;

import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class KamisIngredientMapLoader {

	private final ObjectMapper objectMapper;

	public List<KamisIngredientMapEntry> load() {
		ClassPathResource resource = new ClassPathResource("kamis-ingredient-map.json");
		try (InputStream is = resource.getInputStream()) {
			KamisIngredientMapEntry[] arr = objectMapper.readValue(is, KamisIngredientMapEntry[].class);
			return List.of(arr);
		} catch (IOException e) {
			throw new IllegalStateException("Failed to load kamis-ingredient-map.json", e);
		}
	}

	public record KamisIngredientMapEntry(String ingredientName, KamisQuery kamis) {
	}

	public record KamisQuery(
			String itemCategoryCode,
			String itemCode,
			String kindCode,
			String productRankCode,
			String countryCode,
			String convertKgYn) {
	}
}
