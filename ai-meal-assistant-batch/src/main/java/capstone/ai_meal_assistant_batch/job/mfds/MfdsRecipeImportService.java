package capstone.ai_meal_assistant_batch.job.mfds;

import org.springframework.stereotype.Service;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class MfdsRecipeImportService {

	/**
	 * TODO: 식약처 API 연동 후 구현
	 * - 단발성 실행을 기본으로 하며, 필요 시 재실행/멱등성이 보장되도록 upsert 권장
	 */
	public MfdsRecipeImportResult importAll() {
		return new MfdsRecipeImportResult(0, 0, 0, 0);
	}
}
