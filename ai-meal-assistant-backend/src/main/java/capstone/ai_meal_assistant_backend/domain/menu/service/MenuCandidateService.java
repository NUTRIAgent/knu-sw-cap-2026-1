package capstone.ai_meal_assistant_backend.domain.menu.service;

import capstone.ai_meal_assistant_backend.domain.history.repository.RecommendationLogRepository;
import capstone.ai_meal_assistant_backend.domain.menu.dto.MenuCandidateDto;
import capstone.ai_meal_assistant_backend.domain.menu.entity.Allergy;
import capstone.ai_meal_assistant_backend.domain.menu.entity.Menu;
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

import java.util.*;
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
    private final RecommendationLogRepository recommendationLogRepository;

    public List<MenuCandidateDto> getCandidates(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        UserPreference pref = preferenceRepository.findByUser(user).orElse(null);

        Set<Long> excludeMenuIds = new HashSet<>(getExcludeMenuIds(user));
        excludeMenuIds.addAll(recommendationLogRepository.findNegativeMenuIdsByUser(user));

        Integer budget     = pref != null ? pref.getMealBudget() : null;
        Double  minProtein = resolveMinProtein(pref);

        Set<Long> queryExclude = excludeMenuIds.isEmpty() ? Set.of(-1L) : excludeMenuIds;
        List<Menu> menus = menuRepository.findCandidates(queryExclude, budget, minProtein, null, CANDIDATE_LIMIT);
        return buildDtos(menus);
    }

    public List<MenuCandidateDto> getRandomCandidates() {
        List<Menu> menus = menuRepository.findCandidates(Set.of(-1L), null, null, null, CANDIDATE_LIMIT);
        return buildDtos(menus);
    }

    public List<MenuCandidateDto> getCandidatesByIds(List<Long> ids) {
        List<Menu> menus = menuRepository.findAllById(ids);
        return buildDtos(menus);
    }

    private List<MenuCandidateDto> buildDtos(List<Menu> menus) {
        if (menus.isEmpty()) return Collections.emptyList();

        List<Long> menuIds = menus.stream().map(Menu::getId).collect(Collectors.toList());

        Map<Long, String> ingredientsMap = new HashMap<>();
        for (Object[] row : menuRepository.findIngredientsTextByMenuIds(menuIds)) {
            Long menuId = ((Number) row[0]).longValue();
            ingredientsMap.put(menuId, (String) row[1]);
        }

        return menus.stream()
                .map(m -> MenuCandidateDto.from(
                        m,
                        ingredientsMap.getOrDefault(m.getId(), ""),
                        Collections.emptyList()
                ))
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

    private Double resolveMinProtein(UserPreference pref) {
        if (pref == null || pref.getProteinLevel() == null) return null;
        if (pref.getProteinLevel() == ProteinLevel.HIGH) return 25.0;
        return null;
    }
}
