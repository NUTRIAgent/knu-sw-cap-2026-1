package capstone.ai_meal_assistant_backend.domain.history.service;

import capstone.ai_meal_assistant_backend.domain.history.entity.RecommendationLog;
import capstone.ai_meal_assistant_backend.domain.history.repository.RecommendationLogRepository;
import capstone.ai_meal_assistant_backend.domain.menu.entity.Menu;
import capstone.ai_meal_assistant_backend.domain.menu.repository.MenuRepository;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;

@Service
@RequiredArgsConstructor
public class RecommendationLogService {

    private final RecommendationLogRepository recommendationLogRepository;
    private final UserRepository userRepository;
    private final MenuRepository menuRepository;

    @Transactional
    public void saveFeedback(String email, Long menuId, int feedbackScore) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        Menu menu = menuRepository.findById(menuId)
                .orElseThrow(() -> new IllegalArgumentException("메뉴를 찾을 수 없습니다."));

        RecommendationLog log = new RecommendationLog();
        log.setUser(user);
        log.setSelectedMenu(menu);
        log.setFeedbackScore(feedbackScore);
        recommendationLogRepository.save(log);
    }

    @Transactional(readOnly = true)
    public Set<Long> getNegativeMenuIds(User user) {
        return recommendationLogRepository.findNegativeMenuIdsByUser(user);
    }
}
