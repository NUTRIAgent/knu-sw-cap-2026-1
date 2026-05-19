package capstone.ai_meal_assistant_batch.job.kamis;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class KamisNameMatcherTest {

	@Test
	void similarity_shouldBeHigh_forSameWordWithSuffixes() {
		double score = KamisNameMatcher.similarity("감자", "감자(수미)");
		assertThat(score).isGreaterThan(0.8);
	}

	@Test
	void similarity_shouldBeLow_forUnrelatedWords() {
		double score = KamisNameMatcher.similarity("감자", "바나나");
		assertThat(score).isLessThan(0.6);
	}
}
