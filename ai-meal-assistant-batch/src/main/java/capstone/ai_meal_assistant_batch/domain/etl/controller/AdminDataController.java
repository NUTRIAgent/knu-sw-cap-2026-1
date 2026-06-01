package capstone.ai_meal_assistant_batch.domain.etl.controller;

import capstone.ai_meal_assistant_batch.domain.ingredient.service.ImageRecoveryAsyncRunner;
import capstone.ai_meal_assistant_batch.domain.ingredient.service.RecipeDataSyncService;
import capstone.ai_meal_assistant_batch.job.youtube.YoutubeVideoMappingResult;
import capstone.ai_meal_assistant_batch.job.youtube.YoutubeVideoMappingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/data")
@RequiredArgsConstructor
public class AdminDataController {

    private final RecipeDataSyncService syncService;
    private final ImageRecoveryAsyncRunner imageRecoveryAsyncRunner;
    private final YoutubeVideoMappingService youtubeVideoMappingService;

    @PostMapping("/sync-recipes")
    public ResponseEntity<String> syncRecipes(){
        syncService.syncAllDataFromApi();
        return ResponseEntity.ok("레시피 데이터 동기화가 성공적으로 완료되었습니다!");
    }

    @PostMapping("/sync-allergies")
    public ResponseEntity<String> syncAllergies(){
        syncService.syncAllergyMappings();
        return ResponseEntity.ok("메뉴-알레르기 매핑이 성공적으로 완료되었습니다!");
    }

    /**
     * 이미 적재된 메뉴 기준으로 menu_ingredients를 현재 파서로 재구축.
     * 파서 변경 후 기존 DB를 교정할 때 사용 (menus/이미지/기존 가격 무영향).
     */
    @PostMapping("/rebuild-ingredients")
    public ResponseEntity<String> rebuildIngredients(){
        syncService.rebuildMenuIngredients();
        return ResponseEntity.ok("menu_ingredients 재구축이 완료되었습니다. (자세한 내역은 서버 로그)");
    }

    /**
     * 레시피 미사용 + 즐겨찾기 미참조 재료를 정리(가격·KAMIS 매핑 포함 삭제).
     * 보통 rebuild-ingredients 직후 옛 이름 잔여 행 정리에 사용.
     */
    @PostMapping("/cleanup-unused-ingredients")
    public ResponseEntity<String> cleanupUnusedIngredients(){
        int deleted = syncService.deleteUnusedIngredients();
        return ResponseEntity.ok("미사용 재료 " + deleted + "건을 정리했습니다.");
    }

    /**
     * 메뉴별 유튜브 대표 영상(videoId)을 YouTube Data API로 검색해 menus.youtube_video_id에 적재.
     * 이미 매핑된 메뉴는 건너뛴다(idempotent).
     *
     * @param dryRun true(기본)면 DB 저장 없이 검색만 수행해 결과만 확인. 실제 적재는 dryRun=false 필요.
     * @param limit  이번 실행에서 검색 시도할 미매핑 메뉴 최대 수(할당량 보호). 미지정 시 전체.
     *
     * 예) 소량 확인: POST /api/admin/data/map-youtube-videos?limit=5
     *     실제 적재: POST /api/admin/data/map-youtube-videos?dryRun=false&limit=50
     */
    @PostMapping("/map-youtube-videos")
    public ResponseEntity<String> mapYoutubeVideos(
            @RequestParam(defaultValue = "true") boolean dryRun,
            @RequestParam(required = false) Integer limit) {
        YoutubeVideoMappingResult result = youtubeVideoMappingService.mapVideos(dryRun, limit);
        return ResponseEntity.ok(result.toString());
    }

    @PostMapping("/recover-images")
    public ResponseEntity<String> recoverImages(){
        boolean started = imageRecoveryAsyncRunner.tryStart();
        if (!started) {
            return ResponseEntity.status(409)
                    .body("손상 이미지 복구 작업이 이미 진행 중입니다. 서버 로그를 확인하세요.");
        }
        return ResponseEntity.accepted()
                .body("손상 이미지 복구 작업을 백그라운드에서 시작했습니다. 진행 상황은 서버 로그를 확인하세요.");
    }
}
