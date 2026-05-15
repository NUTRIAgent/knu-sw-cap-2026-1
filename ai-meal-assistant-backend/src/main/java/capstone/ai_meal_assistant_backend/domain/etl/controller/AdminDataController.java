package capstone.ai_meal_assistant_backend.domain.etl.controller;

import capstone.ai_meal_assistant_backend.domain.ingredient.service.RecipeDataSyncService;
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

    @PostMapping("/sync-recipes")
    public ResponseEntity<String> syncRecipes(){
        syncService.syncAllDataFromApi();
        return ResponseEntity.ok("레시피 데이터 동기화가 성공적으로 완료되었습니다!");
    }
}
