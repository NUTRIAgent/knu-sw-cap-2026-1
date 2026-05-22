// 사용자 프로필(인바디/선호/알러지) 관련 모델

class UserProfileRequest {
  final String? nickname;
  final String? gender;
  final double? height;
  final double? weight;
  final double? skeletalMuscleMass;
  final double? bodyFatPercentage;
  final double? bmi;
  final int? bmr;
  final int? inbodyScore;
  final String? measurementDate; // yyyy-MM-dd

  final int? mealBudget;
  final String? vegetarianType; // e.g. NONE, VEGAN...
  final int? spicyPreference; // 1~5
  final String? proteinLevel; // e.g. LOW, NORMAL, HIGH
  final String? fitnessGoal; // e.g. DIET, MUSCLE_GAIN, MAINTAIN, GENERAL
  final List<String>? foodPreferences;
  final List<String>? allergies;
  final List<String>? healthConditions;

  UserProfileRequest({
    this.nickname,
    this.gender,
    this.height,
    this.weight,
    this.skeletalMuscleMass,
    this.bodyFatPercentage,
    this.bmi,
    this.bmr,
    this.inbodyScore,
    this.measurementDate,
    this.mealBudget,
    this.vegetarianType,
    this.spicyPreference,
    this.proteinLevel,
    this.fitnessGoal,
    this.foodPreferences,
    this.allergies,
    this.healthConditions,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (nickname != null) data['nickname'] = nickname;
    if (gender != null) data['gender'] = gender;
    if (height != null) data['height'] = height;
    if (weight != null) data['weight'] = weight;
    if (skeletalMuscleMass != null) data['skeletalMuscleMass'] = skeletalMuscleMass;
    if (bodyFatPercentage != null) data['bodyFatPercentage'] = bodyFatPercentage;
    if (bmi != null) data['bmi'] = bmi;
    if (bmr != null) data['bmr'] = bmr;
    if (inbodyScore != null) data['inbodyScore'] = inbodyScore;
    if (measurementDate != null) data['measurementDate'] = measurementDate;
    if (mealBudget != null) data['mealBudget'] = mealBudget;
    if (vegetarianType != null) data['vegetarianType'] = vegetarianType;
    if (spicyPreference != null) data['spicyPreference'] = spicyPreference;
    if (proteinLevel != null) data['proteinLevel'] = proteinLevel;
    if (fitnessGoal != null) data['fitnessGoal'] = fitnessGoal;
    if (foodPreferences != null) data['foodPreferences'] = foodPreferences;
    if (allergies != null) data['allergies'] = allergies;
    if (healthConditions != null) data['healthConditions'] = healthConditions;
    return data;
  }
}

class UserProfileResponse {
  final bool success;
  final String? message;
  final UserProfileData? data;
  final String? error;

  const UserProfileResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
  });

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null ? UserProfileData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}

class UserProfileData {
  final int? userId;

  // 기본 정보
  final String? nickname;
  final String? gender;

  final double? height;
  final double? weight;
  final double? skeletalMuscleMass;
  final double? bodyFatPercentage;
  final double? bmi;
  final int? bmr;
  final int? inbodyScore;
  final String? measurementDate;

  final int? mealBudget;
  final String? vegetarianType;
  final int? spicyPreference;
  final String? proteinLevel;
  final String? fitnessGoal;
  final List<String> foodPreferences;
  final List<String> allergies;
  final List<String> healthConditions;

  const UserProfileData({
    this.userId,
    this.nickname,
    this.gender,
    this.height,
    this.weight,
    this.skeletalMuscleMass,
    this.bodyFatPercentage,
    this.bmi,
    this.bmr,
    this.inbodyScore,
    this.measurementDate,
    this.mealBudget,
    this.vegetarianType,
    this.spicyPreference,
    this.proteinLevel,
    this.fitnessGoal,
    this.foodPreferences = const [],
    this.allergies = const [],
    this.healthConditions = const [],
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      userId: json['userId'],
      nickname: json['nickname'],
      gender: json['gender']?.toString(),
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      skeletalMuscleMass: (json['skeletalMuscleMass'] as num?)?.toDouble(),
      bodyFatPercentage: (json['bodyFatPercentage'] as num?)?.toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble(),
      bmr: json['bmr'],
      inbodyScore: json['inbodyScore'],
      measurementDate: json['measurementDate'],
      mealBudget: json['mealBudget'],
      vegetarianType: json['vegetarianType'],
      spicyPreference: json['spicyPreference'],
      proteinLevel: json['proteinLevel'],
      fitnessGoal: json['fitnessGoal'],
      foodPreferences: (json['foodPreferences'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      allergies: (json['allergies'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      healthConditions: (json['healthConditions'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
