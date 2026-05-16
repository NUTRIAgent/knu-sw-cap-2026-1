package capstone.ai_meal_assistant_batch;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
		"spring.main.web-application-type=none",
		"batch.kamis.enabled=false",
		"batch.mfds.enabled=false"
})
class ContextLoadTest {

	@Test
	void contextLoads() {
		// just a smoke test
	}
}
