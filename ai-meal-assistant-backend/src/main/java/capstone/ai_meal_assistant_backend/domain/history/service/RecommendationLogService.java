package capstone.ai_meal_assistant_backend.domain.history.service;

import capstone.ai_meal_assistant_backend.domain.history.dto.RecommendationLogResponse;
import capstone.ai_meal_assistant_backend.domain.history.entity.RecommendationLog;
import capstone.ai_meal_assistant_backend.domain.history.repository.RecommendationLogRepository;
import capstone.ai_meal_assistant_backend.domain.menu.entity.Menu;
import capstone.ai_meal_assistant_backend.domain.menu.repository.MenuRepository;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RecommendationLogService {

    private final RecommendationLogRepository recommendationLogRepository;
    private final UserRepository userRepository;
    private final MenuRepository menuRepository;

    @Transactional
    public void saveFeedback(String email, Long menuId, Integer feedbackScore, Integer starRating, String feedbackReason) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        Menu menu = menuRepository.findById(menuId)
                .orElseThrow(() -> new IllegalArgumentException("메뉴를 찾을 수 없습니다."));

        RecommendationLog log = recommendationLogRepository
                .findByUserAndSelectedMenu(user, menu)
                .orElseGet(() -> {
                    RecommendationLog newLog = new RecommendationLog();
                    newLog.setUser(user);
                    newLog.setSelectedMenu(menu);
                    return newLog;
                });
        log.setFeedbackScore(feedbackScore);
        log.setStarRating(starRating);
        log.setFeedbackReason(feedbackReason);
        recommendationLogRepository.save(log);
    }

    @Transactional
    public Long saveAiResult(String email, Long menuId, String aiResultJson) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        Menu menu = menuRepository.findById(menuId)
                .orElseThrow(() -> new IllegalArgumentException("메뉴를 찾을 수 없습니다."));

        RecommendationLog log = recommendationLogRepository
                .findByUserAndSelectedMenu(user, menu)
                .orElseGet(() -> {
                    RecommendationLog newLog = new RecommendationLog();
                    newLog.setUser(user);
                    newLog.setSelectedMenu(menu);
                    return newLog;
                });
        log.setAiResultJson(aiResultJson);
        return recommendationLogRepository.save(log).getId();
    }

    @Transactional
    public void updateFeedback(String email, Long logId, Integer feedbackScore, Integer starRating, String feedbackReason) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        RecommendationLog log = recommendationLogRepository.findById(logId)
                .orElseThrow(() -> new IllegalArgumentException("이력을 찾을 수 없습니다."));
        if (!log.getUser().getId().equals(user.getId())) {
            throw new SecurityException("권한이 없습니다.");
        }
        if (feedbackScore != null) log.setFeedbackScore(feedbackScore);
        if (starRating != null) log.setStarRating(starRating);
        if (feedbackReason != null) log.setFeedbackReason(feedbackReason);
        recommendationLogRepository.save(log);
    }

    @Transactional(readOnly = true)
    public Set<Long> getNegativeMenuIds(User user) {
        return recommendationLogRepository.findNegativeMenuIdsByUser(user);
    }

    @Transactional(readOnly = true)
    public List<RecommendationLogResponse> getUserFeedbacks(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        return recommendationLogRepository.findFeedbacksByUser(user).stream()
                .map(log -> RecommendationLogResponse.builder()
                        .id(log.getId())
                        .menuId(log.getSelectedMenu().getId())
                        .menuName(log.getSelectedMenu().getName())
                        .menuImageUrl(log.getSelectedMenu().getMainImageUrl())
                        .feedbackScore(log.getFeedbackScore())
                        .createdAt(log.getCreatedAt())
                        .build())
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<RecommendationLogResponse> getUserAiPickHistory(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        return recommendationLogRepository.findAiPicksByUser(user).stream()
                .map(log -> RecommendationLogResponse.builder()
                        .id(log.getId())
                        .menuId(log.getSelectedMenu().getId())
                        .menuName(log.getSelectedMenu().getName())
                        .menuImageUrl(log.getSelectedMenu().getMainImageUrl())
                        .feedbackScore(log.getFeedbackScore())
                        .starRating(log.getStarRating())
                        .feedbackReason(log.getFeedbackReason())
                        .aiResultJson(log.getAiResultJson())
                        .createdAt(log.getCreatedAt())
                        .build())
                .collect(Collectors.toList());
    }

    @Transactional
    public void deleteFeedback(String email, Long logId) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        RecommendationLog log = recommendationLogRepository.findById(logId)
                .orElseThrow(() -> new IllegalArgumentException("피드백을 찾을 수 없습니다."));
        if (!log.getUser().getId().equals(user.getId())) {
            throw new SecurityException("권한이 없습니다.");
        }
        recommendationLogRepository.delete(log);
    }
}
