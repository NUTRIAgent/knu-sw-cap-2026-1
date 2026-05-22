package capstone.ai_meal_assistant_backend.domain.user.service;

import capstone.ai_meal_assistant_backend.domain.menu.entity.Allergy;
import capstone.ai_meal_assistant_backend.domain.menu.entity.UserAllergy;
import capstone.ai_meal_assistant_backend.domain.menu.repository.AllergyRepository;
import capstone.ai_meal_assistant_backend.domain.menu.repository.UserAllergyRepository;
import capstone.ai_meal_assistant_backend.domain.user.dto.UserProfileRequest;
import capstone.ai_meal_assistant_backend.domain.user.dto.UserProfileResponse;
import capstone.ai_meal_assistant_backend.domain.user.entity.FitnessGoal;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.domain.user.entity.UserHealthProfile;
import capstone.ai_meal_assistant_backend.domain.user.entity.UserPreference;
import capstone.ai_meal_assistant_backend.domain.user.repository.UserHealthProfileRepository;
import capstone.ai_meal_assistant_backend.domain.user.repository.UserPreferenceRepository;
import capstone.ai_meal_assistant_backend.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserProfileService {

    private final UserRepository userRepository;
    private final UserHealthProfileRepository healthProfileRepository;
    private final UserPreferenceRepository preferenceRepository;
    private final AllergyRepository allergyRepository;
    private final UserAllergyRepository userAllergyRepository;

    @Transactional
    public UserProfileResponse saveOrUpdateProfile(String email, UserProfileRequest request) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        // 온보딩 때는 null이 들어오겠지만, 엔티티 내부에 방어막이 있어서 DB가 터지지 않음.
        // 마이페이지 수정 때는 값이 들어오므로 정상적으로 업데이트됨
        if (request.getNickname() != null || request.getGender() != null) {
            user.updateNicknameAndGender(request.getNickname(), request.getGender());
        } 

        // 1. 건강 정보 저장/수정
        UserHealthProfile healthProfile = healthProfileRepository.findByUser(user)
                .orElse(null);

        if (healthProfile == null) {
            // 새로 생성
            healthProfile = UserHealthProfile.builder()
                    .user(user)
                    .height(request.getHeight())
                    .weight(request.getWeight())
                    .skeletalMuscleMass(request.getSkeletalMuscleMass())
                    .bodyFatPercentage(request.getBodyFatPercentage())
                    .bmi(request.getBmi())
                    .bmr(request.getBmr())
                    .inbodyScore(request.getInbodyScore())
                    .measurementDate(request.getMeasurementDate())
                    .build();
            healthProfileRepository.save(healthProfile);
        } else {
            // 기존 데이터 수정
            healthProfile.updateProfile(
                    request.getHeight(),
                    request.getWeight(),
                    request.getSkeletalMuscleMass(),
                    request.getBodyFatPercentage(),
                    request.getBmi(),
                    request.getBmr(),
                    request.getInbodyScore(),
                    request.getMeasurementDate()
            );
        }

        // 2. 선호 정보 저장/수정
        UserPreference preference = preferenceRepository.findByUser(user)
                .orElse(null);

        if (preference == null) {
            // 새로 생성
            preference = UserPreference.builder()
                    .user(user)
                    .mealBudget(request.getMealBudget())
                    .vegetarianType(request.getVegetarianType())
                    .spicyPreference(request.getSpicyPreference())
                    .proteinLevel(request.getProteinLevel())
                    .fitnessGoal(request.getFitnessGoal() != null ? request.getFitnessGoal() : FitnessGoal.GENERAL)
                    .foodPreferences(request.getFoodPreferences() != null ? request.getFoodPreferences() : new java.util.ArrayList<>())
                    .healthConditions(request.getHealthConditions() != null ? request.getHealthConditions() : new java.util.ArrayList<>())
                    .build();
            preferenceRepository.save(preference);
        } else {
            // 기존 데이터 수정
            preference.updatePreference(
                    request.getMealBudget(),
                    request.getVegetarianType(),
                    request.getSpicyPreference(),
                    request.getProteinLevel(),
                    request.getFitnessGoal(),
                    request.getFoodPreferences(),
                    request.getHealthConditions()
            );
        }

        // 3. 알러지 정보 저장/수정
        // 기존 알러지 정보 삭제
        userAllergyRepository.deleteByUser(user);

        // 새로운 알러지 정보 저장
        if (request.getAllergies() != null && !request.getAllergies().isEmpty()) {
            for (String allergyName : request.getAllergies()) {
                // 알러지가 DB에 없으면 생성, 있으면 조회
                Allergy allergy = allergyRepository.findByName(allergyName)
                        .orElseGet(() -> allergyRepository.save(
                                Allergy.builder()
                                        .name(allergyName)
                                        .build()
                        ));

                // UserAllergy 생성
                UserAllergy userAllergy = UserAllergy.builder()
                        .user(user)
                        .allergy(allergy)
                        .build();
                userAllergyRepository.save(userAllergy);
            }
        }

        // 4. 응답 생성
        return buildProfileResponse(user);
    }

    public UserProfileResponse getProfile(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다."));

        return buildProfileResponse(user);
    }

    private UserProfileResponse buildProfileResponse(User user) {
        // 건강 정보 조회
        UserHealthProfile healthProfile = healthProfileRepository.findByUser(user).orElse(null);

        // 선호 정보 조회
        UserPreference preference = preferenceRepository.findByUser(user).orElse(null);

        // 알러지 정보 조회
        List<String> allergies = userAllergyRepository.findByUser(user)
                .stream()
                .map(userAllergy -> userAllergy.getAllergy().getName())
                .collect(Collectors.toList());

        return UserProfileResponse.builder()
                .nickname(user.getNickname())
                .gender(user.getGender())
                .height(healthProfile != null ? healthProfile.getHeight() : null)
                .weight(healthProfile != null ? healthProfile.getWeight() : null)
                .skeletalMuscleMass(healthProfile != null ? healthProfile.getSkeletalMuscleMass() : null)
                .bodyFatPercentage(healthProfile != null ? healthProfile.getBodyFatPercentage() : null)
                .bmi(healthProfile != null ? healthProfile.getBmi() : null)
                .bmr(healthProfile != null ? healthProfile.getBmr() : null)
                .inbodyScore(healthProfile != null ? healthProfile.getInbodyScore() : null)
                .measurementDate(healthProfile != null ? healthProfile.getMeasurementDate() : null)
                .mealBudget(preference != null ? preference.getMealBudget() : null)
                .vegetarianType(preference != null ? preference.getVegetarianType() : null)
                .spicyPreference(preference != null ? preference.getSpicyPreference() : null)
                .proteinLevel(preference != null ? preference.getProteinLevel() : null)
                .fitnessGoal(preference != null ? preference.getFitnessGoal() : null)
                .foodPreferences(preference != null ? preference.getFoodPreferences() : List.of())
                .allergies(allergies)
                .healthConditions(preference != null ? preference.getHealthConditions() : List.of())
                .build();
    }
}