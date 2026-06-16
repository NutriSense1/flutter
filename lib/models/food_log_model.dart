import 'scan_result_model.dart';

class FoodLogModel {
  final String id;
  final String userId;
  final String productName;
  final String? brand;
  final String? imageUrl;
  final String mealType;
  final double servingSize;
  final String servingUnit;
  final double servingsConsumed;
  final NutritionInfo nutritionInfo;
  final double healthScore;
  final String? scanId;
  final DateTime loggedAt;

  const FoodLogModel({
    required this.id,
    required this.userId,
    required this.productName,
    this.brand,
    this.imageUrl,
    required this.mealType,
    required this.servingSize,
    required this.servingUnit,
    this.servingsConsumed = 1.0,
    required this.nutritionInfo,
    required this.healthScore,
    this.scanId,
    required this.loggedAt,
  });

  double get totalCalories => nutritionInfo.calories * servingsConsumed;
  double get totalProtein => nutritionInfo.protein * servingsConsumed;
  double get totalCarbs => nutritionInfo.carbs * servingsConsumed;
  double get totalFat => nutritionInfo.fat * servingsConsumed;

  factory FoodLogModel.fromJson(Map<String, dynamic> json) => FoodLogModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        productName: json['product_name'] as String,
        brand: json['brand'] as String?,
        imageUrl: json['image_url'] as String?,
        mealType: json['meal_type'] as String,
        servingSize: (json['serving_size'] as num).toDouble(),
        servingUnit: json['serving_unit'] as String,
        servingsConsumed: (json['servings_consumed'] as num?)?.toDouble() ?? 1.0,
        nutritionInfo: NutritionInfo.fromJson(json['nutrition_info'] ?? {}),
        healthScore: (json['health_score'] as num?)?.toDouble() ?? 50,
        scanId: json['scan_id'] as String?,
        loggedAt: DateTime.parse(json['logged_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'product_name': productName,
        'brand': brand,
        'image_url': imageUrl,
        'meal_type': mealType,
        'serving_size': servingSize,
        'serving_unit': servingUnit,
        'servings_consumed': servingsConsumed,
        'nutrition_info': nutritionInfo.toJson(),
        'health_score': healthScore,
        'scan_id': scanId,
        'logged_at': loggedAt.toIso8601String(),
      };
}

class DailySummary {
  final DateTime date;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final double totalSugar;
  final double avgHealthScore;
  final int mealCount;
  final List<FoodLogModel> logs;

  const DailySummary({
    required this.date,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.totalFiber,
    required this.totalSugar,
    required this.avgHealthScore,
    required this.mealCount,
    required this.logs,
  });

  factory DailySummary.fromLogs(DateTime date, List<FoodLogModel> logs) {
    if (logs.isEmpty) {
      return DailySummary(
        date: date,
        totalCalories: 0,
        totalProtein: 0,
        totalCarbs: 0,
        totalFat: 0,
        totalFiber: 0,
        totalSugar: 0,
        avgHealthScore: 0,
        mealCount: 0,
        logs: [],
      );
    }
    return DailySummary(
      date: date,
      totalCalories: logs.fold(0, (s, l) => s + l.totalCalories),
      totalProtein: logs.fold(0, (s, l) => s + l.totalProtein),
      totalCarbs: logs.fold(0, (s, l) => s + l.totalCarbs),
      totalFat: logs.fold(0, (s, l) => s + l.totalFat),
      totalFiber: logs.fold(0, (s, l) => s + l.nutritionInfo.fiber * l.servingsConsumed),
      totalSugar: logs.fold(0, (s, l) => s + l.nutritionInfo.sugar * l.servingsConsumed),
      avgHealthScore: logs.fold(0.0, (s, l) => s + l.healthScore) / logs.length,
      mealCount: logs.length,
      logs: logs,
    );
  }
}
