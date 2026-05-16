package capstone.ai_meal_assistant_batch;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
@ConfigurationPropertiesScan
public class AiMealAssistantBatchApplication {

	public static void main(String[] args) {
		SpringApplication.run(AiMealAssistantBatchApplication.class, args);
	}

}
