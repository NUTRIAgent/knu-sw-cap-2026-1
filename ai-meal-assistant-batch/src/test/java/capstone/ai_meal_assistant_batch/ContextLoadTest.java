package capstone.ai_meal_assistant_batch;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
		"spring.main.web-application-type=none",
		"spring.datasource.url=jdbc:h2:mem:testdb;MODE=MySQL;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE",
		"spring.datasource.driver-class-name=org.h2.Driver",
		"spring.datasource.username=sa",
		"spring.datasource.password=",
		"spring.jpa.database-platform=org.hibernate.dialect.H2Dialect",
		"batch.kamis.enabled=false",
		"batch.mfds.enabled=false",
		"batch.kamis.api.api-key=dummy",
		"batch.kamis.api.cert-id=dummy"
})
class ContextLoadTest {

	@Test
	void contextLoads() {
		// just a smoke test
	}
}
