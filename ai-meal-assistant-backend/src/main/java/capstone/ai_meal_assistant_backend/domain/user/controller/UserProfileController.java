package capstone.ai_meal_assistant_backend.domain.user.controller;

import capstone.ai_meal_assistant_backend.domain.user.dto.UserProfileRequest;
import capstone.ai_meal_assistant_backend.domain.user.dto.UserProfileResponse;
import capstone.ai_meal_assistant_backend.domain.user.service.UserProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserProfileController {

    private final UserProfileService userProfileService;

    /**
     * 사용자 프로필 저장 또는 수정
     * - 인바디 정보
     * - 음식 선호 정보
     * - 알러지 정보
     */
    @PostMapping("/profile")
    public ResponseEntity<UserProfileResponse> saveProfile(
            @RequestParam Long userId,
            @RequestBody UserProfileRequest request) {
        UserProfileResponse response = userProfileService.saveOrUpdateProfile(userId, request);
        return ResponseEntity.ok(response);
    }

    /**
     * 사용자 프로필 수정 (PUT 방식)
     */
    @PutMapping("/profile")
    public ResponseEntity<UserProfileResponse> updateProfile(
            @RequestParam Long userId,
            @RequestBody UserProfileRequest request) {
        UserProfileResponse response = userProfileService.saveOrUpdateProfile(userId, request);
        return ResponseEntity.ok(response);
    }

    /**
     * 사용자 프로필 조회
     */
    @GetMapping("/profile")
    public ResponseEntity<UserProfileResponse> getProfile(@RequestParam Long userId) {
        UserProfileResponse response = userProfileService.getProfile(userId);
        return ResponseEntity.ok(response);
    }
}
