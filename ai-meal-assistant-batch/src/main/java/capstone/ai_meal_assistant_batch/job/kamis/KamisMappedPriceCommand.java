package capstone.ai_meal_assistant_batch.job.kamis;

import java.time.Instant;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.SpringApplication;
import org.springframework.stereotype.Component;

import org.springframework.context.ApplicationContext;

import capstone.ai_meal_assistant_batch.global.log.BatchLog;
import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "batch.kamis", name = "run-once", havingValue = "true")
public class KamisMappedPriceCommand implements ApplicationRunner {

	private static final String JOB_NAME = "kamisMappedPriceUpdate";

	private final KamisPriceUpdateService service;
	private final ApplicationContext applicationContext;

	@Override
	public void run(ApplicationArguments args) {
		Instant start = BatchLog.start(JOB_NAME);
		try {
			KamisPriceUpdateResult result = service.updateTodayPrices(false);
			BatchLog.success(JOB_NAME, start, result);
			int exitCode = SpringApplication.exit(applicationContext, () -> 0);
			System.exit(exitCode);
		} catch (Exception e) {
			BatchLog.fail(JOB_NAME, start, e);
			throw e;
		}
	}
}
