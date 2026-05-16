package capstone.ai_meal_assistant_batch.global.log;

import java.time.Duration;
import java.time.Instant;

import lombok.extern.slf4j.Slf4j;

@Slf4j
public final class BatchLog {

	private BatchLog() {
	}

	public static Instant start(String jobName) {
		Instant start = Instant.now();
		log.info("[BATCH][START] {}", jobName);
		return start;
	}

	public static void success(String jobName, Instant start, Object details) {
		long ms = Duration.between(start, Instant.now()).toMillis();
		log.info("[BATCH][SUCCESS] {} elapsedMs={} details={}", jobName, ms, details);
	}

	public static void fail(String jobName, Instant start, Exception e) {
		long ms = Duration.between(start, Instant.now()).toMillis();
		log.error("[BATCH][FAIL] {} elapsedMs={} message={}", jobName, ms, e.getMessage(), e);
	}
}
