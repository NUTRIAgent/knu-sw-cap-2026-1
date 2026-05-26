package capstone.ai_meal_assistant_batch.job.kamis;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "batch.kamis", name = "dry-run", havingValue = "true")
public class KamisDryRunCommand implements ApplicationRunner {

	private final KamisPriceUpdateService service;

	@Override
	public void run(ApplicationArguments args) {
		log.info("[BATCH][DRYRUN] kamisPriceUpdate started");
		KamisPriceUpdateResult result = service.updateTodayPrices(true, false);
		log.info("[BATCH][DRYRUN] kamisPriceUpdate result={}", result);
	}
}
