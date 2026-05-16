package capstone.ai_meal_assistant_batch.job.mfds;

public record MfdsRecipeImportResult(int totalFetched, int inserted, int updated, int skipped) {
}
