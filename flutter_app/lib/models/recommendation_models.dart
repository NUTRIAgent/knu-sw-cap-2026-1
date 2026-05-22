class RecommendationRequest {
  final double heightCm;
  final double weightKg;
  final String location;
  final double budget;
  final List<String> healthConditions;
  final String fitnessGoal;
  final List<String> allergies;
  final List<String> preferences;
  final String? jwtToken;
  final List<int> candidateMenuIds;

  const RecommendationRequest({
    required this.heightCm,
    required this.weightKg,
    required this.location,
    required this.budget,
    required this.fitnessGoal,
    this.healthConditions = const [],
    this.allergies = const [],
    this.preferences = const [],
    this.jwtToken,
    this.candidateMenuIds = const [],
  });

  RecommendationRequest copyWith({List<int>? candidateMenuIds}) {
    return RecommendationRequest(
      heightCm: heightCm,
      weightKg: weightKg,
      location: location,
      budget: budget,
      fitnessGoal: fitnessGoal,
      healthConditions: healthConditions,
      allergies: allergies,
      preferences: preferences,
      jwtToken: jwtToken,
      candidateMenuIds: candidateMenuIds ?? this.candidateMenuIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'location': location,
        'budget': budget,
        'health_conditions': healthConditions,
        'fitness_goal': fitnessGoal,
        'allergies': allergies,
        'preferences': preferences,
        if (jwtToken != null) 'jwt_token': jwtToken,
        if (candidateMenuIds.isNotEmpty) 'candidate_menu_ids': candidateMenuIds,
      };
}

class MenuCandidate {
  final int id;
  final String name;
  final String? category;
  final double? calories;
  final double? protein;
  final double? sodium;
  final int? basePrice;
  final String? mainImageUrl;

  const MenuCandidate({
    required this.id,
    required this.name,
    this.category,
    this.calories,
    this.protein,
    this.sodium,
    this.basePrice,
    this.mainImageUrl,
  });

  factory MenuCandidate.fromJson(Map<String, dynamic> json) => MenuCandidate(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        category: json['category'],
        calories: (json['calories'] as num?)?.toDouble(),
        protein: (json['protein'] as num?)?.toDouble(),
        sodium: (json['sodium'] as num?)?.toDouble(),
        basePrice: json['basePrice'],
        mainImageUrl: json['mainImageUrl'],
      );
}

class NutritionInfo {
  final String energy;
  final String protein;
  final String fat;
  final String carbs;
  final String sodium;

  const NutritionInfo({
    required this.energy,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.sodium,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) => NutritionInfo(
        energy: json['energy'] ?? '-',
        protein: json['protein'] ?? '-',
        fat: json['fat'] ?? '-',
        carbs: json['carbs'] ?? '-',
        sodium: json['sodium'] ?? '-',
      );
}

class RecipeStep {
  final int stepNo;
  final String content;
  final String image;

  const RecipeStep({
    required this.stepNo,
    required this.content,
    required this.image,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
        stepNo: json['step_no'] ?? 0,
        content: json['content'] ?? '',
        image: json['image'] ?? '',
      );
}

class MarketPriceItem {
  final String name;
  final String recipeAmount;
  final String marketUnit;
  final num marketPrice;
  final String calculationReasoning;
  final num calculatedCost;

  const MarketPriceItem({
    required this.name,
    required this.recipeAmount,
    required this.marketUnit,
    required this.marketPrice,
    required this.calculationReasoning,
    required this.calculatedCost,
  });

  factory MarketPriceItem.fromJson(Map<String, dynamic> json) => MarketPriceItem(
        name: json['name'] ?? '',
        recipeAmount: json['recipe_amount'] ?? '',
        marketUnit: json['market_unit'] ?? '',
        marketPrice: json['market_price'] ?? 0,
        calculationReasoning: json['calculation_reasoning'] ?? '',
        calculatedCost: json['calculated_cost'] ?? 0,
      );
}

class RecommendationResult {
  final int menuId;
  final String menuName;
  final String mainImg;
  final NutritionInfo nutritionInfo;
  final List<RecipeStep> recipeSteps;
  final String naTip;
  final String selectionReason;
  final String personalizedRecipeTip;
  final num totalEstimatedCost;
  final List<MarketPriceItem> marketPrices;

  const RecommendationResult({
    required this.menuId,
    required this.menuName,
    required this.mainImg,
    required this.nutritionInfo,
    required this.recipeSteps,
    required this.naTip,
    required this.selectionReason,
    this.personalizedRecipeTip = '',
    required this.totalEstimatedCost,
    required this.marketPrices,
  });

  factory RecommendationResult.fromJson(Map<String, dynamic> json) => RecommendationResult(
        menuId: json['menu_id'] ?? 0,
        menuName: json['menu_name'] ?? '',
        mainImg: json['main_img'] ?? '',
        nutritionInfo: NutritionInfo.fromJson(json['nutrition_info'] ?? {}),
        recipeSteps: (json['recipe_steps'] as List? ?? [])
            .map((e) => RecipeStep.fromJson(e))
            .toList(),
        naTip: json['na_tip'] ?? '',
        selectionReason: json['selection_reason'] ?? '',
        personalizedRecipeTip: json['personalized_recipe_tip'] ?? '',
        totalEstimatedCost: json['total_estimated_cost'] ?? 0,
        marketPrices: (json['market_prices'] as List? ?? [])
            .map((e) => MarketPriceItem.fromJson(e))
            .toList(),
      );
}

class MenuDetail {
  final int id;
  final String name;
  final String? category;
  final String? cookingMethod;
  final double? calories;
  final double? protein;
  final double? fat;
  final double? carbs;
  final double? sodium;
  final int? basePrice;
  final String? mainImageUrl;
  final String? healthTip;
  final String? ingredientsText;

  const MenuDetail({
    required this.id,
    required this.name,
    this.category,
    this.cookingMethod,
    this.calories,
    this.protein,
    this.fat,
    this.carbs,
    this.sodium,
    this.basePrice,
    this.mainImageUrl,
    this.healthTip,
    this.ingredientsText,
  });

  factory MenuDetail.fromJson(Map<String, dynamic> json) => MenuDetail(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] ?? '',
        category: json['category'],
        cookingMethod: json['cookingMethod'],
        calories: (json['calories'] as num?)?.toDouble(),
        protein: (json['protein'] as num?)?.toDouble(),
        fat: (json['fat'] as num?)?.toDouble(),
        carbs: (json['carbs'] as num?)?.toDouble(),
        sodium: (json['sodium'] as num?)?.toDouble(),
        basePrice: (json['basePrice'] as num?)?.toInt(),
        mainImageUrl: json['mainImageUrl'],
        healthTip: json['healthTip'],
        ingredientsText: json['ingredientsText'],
      );
}
