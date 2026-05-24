package capstone.ai_meal_assistant_backend.domain.ingredient.controller;

import capstone.ai_meal_assistant_backend.domain.ingredient.dto.AutoConfirmResult;
import capstone.ai_meal_assistant_backend.domain.ingredient.dto.KamisMappingGroupResponse;
import capstone.ai_meal_assistant_backend.domain.ingredient.dto.KamisMappingPatchRequest;
import capstone.ai_meal_assistant_backend.domain.ingredient.service.AdminKamisMappingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/admin/kamis-mappings")
@RequiredArgsConstructor
public class AdminKamisMappingController {

    private final AdminKamisMappingService service;

    @GetMapping
    public ResponseEntity<List<KamisMappingGroupResponse>> getUnconfirmedMappings() {
        return ResponseEntity.ok(service.getUnconfirmedMappings());
    }

    @PatchMapping("/{id}")
    public ResponseEntity<Void> patchMapping(
            @PathVariable Long id,
            @RequestBody KamisMappingPatchRequest request) {
        service.patchMapping(id, request);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/auto-confirm")
    public ResponseEntity<AutoConfirmResult> autoConfirm(
            @RequestParam(name = "minScore", defaultValue = "0.85") double minScore,
            @RequestParam(name = "deleteBelow", defaultValue = "0.333") double deleteBelow) {
        return ResponseEntity.ok(service.autoConfirm(minScore, deleteBelow));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteMapping(@PathVariable Long id) {
        service.deleteMapping(id);
        return ResponseEntity.noContent().build();
    }
}
