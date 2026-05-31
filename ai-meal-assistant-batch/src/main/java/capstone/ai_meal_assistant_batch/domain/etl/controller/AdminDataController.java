package capstone.ai_meal_assistant_batch.domain.etl.controller;

import capstone.ai_meal_assistant_batch.domain.ingredient.service.ImageRecoveryAsyncRunner;
import capstone.ai_meal_assistant_batch.domain.ingredient.service.RecipeDataSyncService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/data")
@RequiredArgsConstructor
public class AdminDataController {

    private final RecipeDataSyncService syncService;
    private final ImageRecoveryAsyncRunner imageRecoveryAsyncRunner;

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
