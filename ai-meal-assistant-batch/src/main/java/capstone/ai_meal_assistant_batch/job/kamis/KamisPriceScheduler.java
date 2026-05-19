package capstone.ai_meal_assistant_batch.job.kamis;

import java.time.Instant;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import capstone.ai_meal_assistant_batch.global.log.BatchLog;
import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
@ConditionalOnProperty(
		prefix = "batch.kamis",
		name = {"enabled", "run-once"},
		havingValue = "true,false",
		matchIfMissing = true)
public class KamisPriceScheduler {

	private static final String JOB_NAME = "kamisPriceUpdate";

	private final KamisPriceUpdateService service;

	@Scheduled(cron = "${batch.kamis.cron}")
	public void run() {
		Instant start = BatchLog.start(JOB_NAME);
		try {
			KamisPriceUpdateResult result = service.updateTodayPrices();
			BatchLog.success(JOB_NAME, start, result);
		} catch (Exception e) {
			BatchLog.fail(JOB_NAME, start, e);
			throw e;
		}
	}
}
