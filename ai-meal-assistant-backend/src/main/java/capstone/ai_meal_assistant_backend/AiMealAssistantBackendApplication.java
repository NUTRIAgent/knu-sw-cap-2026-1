package capstone.ai_meal_assistant_backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication
@EnableJpaAuditing
public class AiMealAssistantBackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(AiMealAssistantBackendApplication.class, args);
	}

}
