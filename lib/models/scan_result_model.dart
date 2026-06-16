class NutritionInfo {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double addedSugar;
  final double sodium;
  final double saturatedFat;
  final double transFat;
  final double cholesterol;
  final double potassium;
  final Map<String, double> vitamins;

  const NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.addedSugar = 0,
    this.sodium = 0,
    this.saturatedFat = 0,
    this.transFat = 0,
    this.cholesterol = 0,
    this.potassium = 0,
    this.vitamins = const {},
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) => NutritionInfo(
        calories: (json['calories'] as num?)?.toDouble() ?? 0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0,
        fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
        sugar: (json['sugar'] as num?)?.toDouble() ?? 0,
        addedSugar: (json['added_sugar'] as num?)?.toDouble() ?? 0,
        sodium: (json['sodium'] as num?)?.toDouble() ?? 0,
        saturatedFat: (json['saturated_fat'] as num?)?.toDouble() ?? 0,
        transFat: (json['trans_fat'] as num?)?.toDouble() ?? 0,
        cholesterol: (json['cholesterol'] as num?)?.toDouble() ?? 0,
        potassium: (json['potassium'] as num?)?.toDouble() ?? 0,
        vitamins: Map<String, double>.from(json['vitamins'] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sugar': sugar,
        'added_sugar': addedSugar,
        'sodium': sodium,
        'saturated_fat': saturatedFat,
        'trans_fat': transFat,
        'cholesterol': cholesterol,
        'potassium': potassium,
        'vitamins': vitamins,
      };
}

enum ScanConfidence { high, medium, low }

class ScanResultModel {
  final String id;
  final String? imageUrl;
  final String productName;
  final String? brand;
  final String foodType;
  final List<String> ingredients;
  final List<String> detectedAdditives;
  final List<String> detectedAllergens;
  final NutritionInfo nutritionInfo;
  final double servingSize;
  final String servingUnit;
  final double healthScore;
  final String healthScoreLabel;
  final String aiVerdict;
  final List<String> positives;
  final List<String> negatives;
  final List<String> recommendations;
  final bool isUltraProcessed;
  final ScanConfidence confidence;
  final DateTime scannedAt;
  final String? mealType;

  const ScanResultModel({
    required this.id,
    this.imageUrl,
    required this.productName,
    this.brand,
    required this.foodType,
    required this.ingredients,
    this.detectedAdditives = const [],
    this.detectedAllergens = const [],
    required this.nutritionInfo,
    this.servingSize = 100,
    this.servingUnit = 'g',
    required this.healthScore,
    required this.healthScoreLabel,
    required this.aiVerdict,
    this.positives = const [],
    this.negatives = const [],
    this.recommendations = const [],
    this.isUltraProcessed = false,
    this.confidence = ScanConfidence.high,
    required this.scannedAt,
    this.mealType,
  });

  factory ScanResultModel.fromJson(Map<String, dynamic> json) => ScanResultModel(
        id: json['id'] as String,
        imageUrl: json['image_url'] as String?,
        productName: json['product_name'] as String,
        brand: json['brand'] as String?,
        foodType: json['food_type'] as String,
        ingredients: List<String>.from(json['ingredients'] ?? []),
        detectedAdditives: List<String>.from(json['detected_additives'] ?? []),
        detectedAllergens: List<String>.from(json['detected_allergens'] ?? []),
        nutritionInfo: NutritionInfo.fromJson(json['nutrition_info'] ?? {}),
        servingSize: (json['serving_size'] as num?)?.toDouble() ?? 100,
        servingUnit: json['serving_unit'] as String? ?? 'g',
        healthScore: (json['health_score'] as num?)?.toDouble() ?? 50,
        healthScoreLabel: json['health_score_label'] as String? ?? 'Fair',
        aiVerdict: json['ai_verdict'] as String? ?? '',
        positives: List<String>.from(json['positives'] ?? []),
        negatives: List<String>.from(json['negatives'] ?? []),
        recommendations: List<String>.from(json['recommendations'] ?? []),
        isUltraProcessed: json['is_ultra_processed'] as bool? ?? false,
        confidence: ScanConfidence.values.firstWhere(
          (e) => e.name == (json['confidence'] as String?),
          orElse: () => ScanConfidence.medium,
        ),
        scannedAt: DateTime.parse(json['scanned_at'] as String? ?? DateTime.now().toIso8601String()),
        mealType: json['meal_type'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'image_url': imageUrl,
        'product_name': productName,
        'brand': brand,
        'food_type': foodType,
        'ingredients': ingredients,
        'detected_additives': detectedAdditives,
        'detected_allergens': detectedAllergens,
        'nutrition_info': nutritionInfo.toJson(),
        'serving_size': servingSize,
        'serving_unit': servingUnit,
        'health_score': healthScore,
        'health_score_label': healthScoreLabel,
        'ai_verdict': aiVerdict,
        'positives': positives,
        'negatives': negatives,
        'recommendations': recommendations,
        'is_ultra_processed': isUltraProcessed,
        'confidence': confidence.name,
        'scanned_at': scannedAt.toIso8601String(),
        'meal_type': mealType,
      };
}
