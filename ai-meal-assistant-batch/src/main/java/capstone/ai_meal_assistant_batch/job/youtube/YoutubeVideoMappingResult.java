package capstone.ai_meal_assistant_batch.job.youtube;

/**
 * 유튜브 영상 매핑 배치 결과.
 *
 * @param totalMenus 전체 메뉴 수
 * @param targeted   이번 실행에서 검색 시도한(미매핑) 메뉴 수
 * @param updated    videoId를 찾아 매핑한 수 (dryRun이면 저장은 안 함)
 * @param notFound   적절한 임베드 가능 영상을 못 찾은 수
 * @param dryRun     true면 DB 저장 없이 검색만 수행
 */
public record YoutubeVideoMappingResult(
        int totalMenus,
        int targeted,
        int updated,
        int notFound,
        boolean dryRun) {

    @Override
    public String toString() {
        return String.format(
                "총 메뉴 %d개 / 대상(미매핑) %d개 처리 / 매핑 %d개 / 미발견 %d개%s",
                totalMenus, targeted, updated, notFound,
                dryRun ? " [DRY-RUN: DB 저장 안 함]" : "");
    }
}
