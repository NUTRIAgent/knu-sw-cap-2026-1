package capstone.ai_meal_assistant_backend.domain.menu.service;

import capstone.ai_meal_assistant_backend.domain.menu.dto.MenuCandidateDto;
import capstone.ai_meal_assistant_backend.domain.menu.entity.Allergy;
import capstone.ai_meal_assistant_backend.domain.menu.entity.UserAllergy;
import capstone.ai_meal_assistant_backend.domain.menu.repository.MenuAllergyRepository;
import capstone.ai_meal_assistant_backend.domain.menu.repository.MenuRepository;
import capstone.ai_meal_assistant_backend.domain.menu.repository.UserAllergyRepository;
import capstone.ai_meal_assistant_backend.domain.user.entity.ProteinLevel;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.domain.user.entity.UserPreference;
import capstone.ai_meal_assistant_backend.domain.user.repository.UserPreferenceRepository;
import capstone.ai_meal_assistant_backend.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class MenuCandidateService {

    private static final int CANDIDATE_LIMIT = 25;

    private final UserRepository userRepository;
    private final UserPreferenceRepository preferenceRepository;
    private final UserAllergyRepository userAllergyRepository;
    private final MenuAllergyRepository menuAllergyRepository;
    private final MenuRepository menuRepository;

    public List<MenuCandidateDto> getCandidates(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        UserPreference pref = preferenceRepository.findByUser(user).orElse(null);

        // 1. 사용자 알레르기 메뉴 ID 수집
        Set<Long> excludeMenuIds = getExcludeMenuIds(user);

        // 2. 선호 조건 추출
        Integer budget     = pref != null ? pref.getMealBudget() : null;
        Double  minProtein = resolveMinProtein(pref);
        Integer maxCal     = null; // fitnessGoal 병합 후 확장 예정

        // 3. 후보 조회 (DB에서 RAND() + LIMIT)
        // 빈 Set은 NOT IN () → SQL 오류 발생. -1L은 실제 메뉴 ID와 겹치지 않으므로 안전한 더미값
        Set<Long> queryExclude = excludeMenuIds.isEmpty() ? Set.of(-1L) : excludeMenuIds;
        return menuRepository
                .findCandidates(queryExclude, budget, minProtein, maxCal, CANDIDATE_LIMIT)
                .stream()
                .map(MenuCandidateDto::from)
                .collect(Collectors.toList());
    }

    private Set<Long> getExcludeMenuIds(User user) {
        List<Allergy> userAllergies = userAllergyRepository.findByUser(user)
                .stream()
                .map(UserAllergy::getAllergy)
                .collect(Collectors.toList());

        if (userAllergies.isEmpty()) return Collections.emptySet();
        return menuAllergyRepository.findMenuIdsByAllergyIn(userAllergies);
    }

    // proteinLevel → 최소 단백질(g) 변환
    private Double resolveMinProtein(UserPreference pref) {
        if (pref == null || pref.getProteinLevel() == null) return null;
        if (pref.getProteinLevel() == ProteinLevel.HIGH) return 25.0;
        return null;
    }
}
