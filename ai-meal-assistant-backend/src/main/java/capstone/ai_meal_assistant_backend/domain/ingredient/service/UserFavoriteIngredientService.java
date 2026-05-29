package capstone.ai_meal_assistant_backend.domain.ingredient.service;

import capstone.ai_meal_assistant_backend.domain.ingredient.entity.Ingredient;
import capstone.ai_meal_assistant_backend.domain.ingredient.entity.UserFavoriteIngredient;
import capstone.ai_meal_assistant_backend.domain.ingredient.repository.IngredientRepository;
import capstone.ai_meal_assistant_backend.domain.ingredient.repository.UserFavoriteIngredientRepository;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Set;

@Service
@RequiredArgsConstructor
public class UserFavoriteIngredientService {

    private final UserFavoriteIngredientRepository favoriteRepository;
    private final UserRepository userRepository;
    private final IngredientRepository ingredientRepository;

    @Transactional(readOnly = true)
    public Set<Long> getFavoriteIds(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        return Set.copyOf(favoriteRepository.findIngredientIdsByUserId(user.getId()));
    }

    @Transactional
    public void addFavorite(String email, Long ingredientId) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        if (favoriteRepository.existsByUserIdAndIngredientId(user.getId(), ingredientId)) return;
        Ingredient ingredient = ingredientRepository.findById(ingredientId)
                .orElseThrow(() -> new IllegalArgumentException("재료를 찾을 수 없습니다: " + ingredientId));
        favoriteRepository.save(UserFavoriteIngredient.builder()
                .user(user)
                .ingredient(ingredient)
                .build());
    }

    @Transactional
    public void removeFavorite(String email, Long ingredientId) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));
        favoriteRepository.deleteByUserIdAndIngredientId(user.getId(), ingredientId);
    }
}
