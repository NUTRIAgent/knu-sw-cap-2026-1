package capstone.ai_meal_assistant_batch.job.mfds;

import java.time.Instant;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import capstone.ai_meal_assistant_batch.global.log.BatchLog;
import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "batch.mfds", name = "enabled", havingValue = "true")
public class MfdsRecipeImportCommand implements CommandLineRunner {

	private static final String JOB_NAME = "mfdsRecipeImport";

	private final MfdsRecipeImportService service;

	@Override
	public void run(String... args) {
		Instant start = BatchLog.start(JOB_NAME);
		try {
			MfdsRecipeImportResult result = service.importAll();
			BatchLog.success(JOB_NAME, start, result);
		} catch (Exception e) {
			BatchLog.fail(JOB_NAME, start, e);
			throw e;
		}
	}
}
