package capstone.ai_meal_assistant_backend.domain.user.service;

import capstone.ai_meal_assistant_backend.domain.history.repository.RecommendationLogRepository;
import capstone.ai_meal_assistant_backend.domain.ingredient.repository.UserFavoriteIngredientRepository;
import capstone.ai_meal_assistant_backend.domain.menu.repository.UserAllergyRepository;
import capstone.ai_meal_assistant_backend.domain.notification.repository.UserDeviceTokenRepository;
import capstone.ai_meal_assistant_backend.domain.notification.repository.UserIngredientAlertRepository;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.domain.user.repository.UserRepository;
import capstone.ai_meal_assistant_backend.global.client.AiHistoryClient;
import capstone.ai_meal_assistant_backend.global.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * 회원탈퇴 — 사용자와 연관된 모든 데이터를 삭제한다.
 * cascade가 없는 자식 엔티티(알레르기/즐겨찾기/디바이스토큰/가격알림/추천이력)를
 * 먼저 정리해야 FK 제약 위반 없이 계정을 삭제할 수 있다.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AccountDeletionService {

    private final UserRepository userRepository;
    private final UserAllergyRepository userAllergyRepository;
    private final UserFavoriteIngredientRepository userFavoriteIngredientRepository;
    private final UserDeviceTokenRepository userDeviceTokenRepository;
    private final UserIngredientAlertRepository userIngredientAlertRepository;
    private final RecommendationLogRepository recommendationLogRepository;
    private final RefreshTokenService refreshTokenService;
    private final AiHistoryClient aiHistoryClient;

    @Transactional
    public ApiResponse<Void> deleteAccount(String email) {
        User user = userRepository.findByEmail(email).orElse(null);
        if (user == null) {
            return ApiResponse.fail("사용자를 찾을 수 없습니다");
        }

        // 1. RAG(ChromaDB)에 적재된 피드백 임베딩 정리 — 하드 삭제 정책 (#171 연동분, 개인 코멘트 포함)
        //    AiHistoryClient는 내부에서 실패를 로깅만 하는 best-effort라 AI 서버 장애여도 탈퇴는 진행된다
        List<Long> logIds = recommendationLogRepository.findIdsByUser(user);
        logIds.forEach(aiHistoryClient::deleteHistory);

        // 2. cascade 미설정 자식 데이터부터 정리 (FK 제약)
        userAllergyRepository.deleteByUser(user);
        userFavoriteIngredientRepository.deleteByUser(user);
        userDeviceTokenRepository.deleteByUser(user);
        userIngredientAlertRepository.deleteByUser(user);
        recommendationLogRepository.deleteByUser(user);

        // 3. 계정 삭제 — healthProfile/preference는 cascade ALL로 함께 삭제
        userRepository.delete(user);

        // 4. 세션 정리 — refresh token 즉시 무효화 (Redis 장애여도 탈퇴는 완료, TTL로 결국 만료)
        try {
            refreshTokenService.invalidate(email);
        } catch (DataAccessException e) {
            log.warn("Redis 장애 — 탈퇴 계정의 refresh token 무효화 생략: email={}", email, e);
        }

        log.info("회원탈퇴 완료: email={}", email);
        return ApiResponse.ok(null);
    }
}
