package capstone.ai_meal_assistant_batch.global.config;

import java.util.Optional;

import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.domain.AuditorAware;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

import jakarta.persistence.Entity;

@Configuration
@EnableJpaAuditing
@ConditionalOnClass(Entity.class)
@ConditionalOnProperty(prefix = "spring.jpa", name = "auditing.enabled", havingValue = "true", matchIfMissing = true)
public class JpaAuditingConfig {

	@Bean
	public AuditorAware<String> auditorProvider() {
		return () -> Optional.of("batch");
	}
}
