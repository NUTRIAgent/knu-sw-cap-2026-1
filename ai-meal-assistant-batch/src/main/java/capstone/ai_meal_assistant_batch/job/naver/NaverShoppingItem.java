package capstone.ai_meal_assistant_batch.job.naver;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record NaverShoppingItem(String title, String lprice) {}
