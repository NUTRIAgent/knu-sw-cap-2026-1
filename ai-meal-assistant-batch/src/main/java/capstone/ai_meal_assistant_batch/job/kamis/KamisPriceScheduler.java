package capstone.ai_meal_assistant_batch.job.kamis;

import java.time.Instant;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import capstone.ai_meal_assistant_batch.global.log.BatchLog;
import capstone.ai_meal_assistant_batch.job.naver.NaverShoppingPriceResult;
import capstone.ai_meal_assistant_batch.job.naver.NaverShoppingPriceService;
import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "batch.kamis", name = "run-once", havingValue = "false")
public class KamisPriceScheduler {

	private static final String JOB_NAME = "kamisPriceUpdate";

	private final KamisPriceUpdateService service;
	private final NaverShoppingPriceService naverShoppingPriceService;

	@EventListener(ApplicationReadyEvent.class)
	public void runOnStartup() {
		Instant start = BatchLog.start(JOB_NAME + ".startup");
		try {
			KamisPriceUpdateResult result = service.updateTodayPricesForced();
			BatchLog.success(JOB_NAME + ".startup", start, result);
		} catch (Exception e) {
			BatchLog.fail(JOB_NAME + ".startup", start, e);
		}
		fetchNaverShoppingPrices();
	}

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
		fetchNaverShoppingPrices();
	}

	private void fetchNaverShoppingPrices() {
		Instant start = BatchLog.start("naverShoppingPriceFetch");
		try {
			NaverShoppingPriceResult result = naverShoppingPriceService.updateAllPrices();
			BatchLog.success("naverShoppingPriceFetch", start, result);
		} catch (Exception e) {
			BatchLog.fail("naverShoppingPriceFetch", start, e);
		}
	}
}
