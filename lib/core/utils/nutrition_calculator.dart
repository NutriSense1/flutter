import 'dart:math';
import '../constants/app_constants.dart';

class NutritionCalculator {
  NutritionCalculator._();

  /// BMI = weight(kg) / height(m)²
  static double calculateBMI(double weightKg, double heightCm) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  static String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  /// Mifflin-St Jeor BMR
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    return gender.toLowerCase() == 'male' ? base + 5 : base - 161;
  }

  /// TDEE = BMR * activity multiplier
  static double calculateTDEE(double bmr, String activityLevel) {
    final multiplier = AppConstants.activityMultipliers[activityLevel] ?? 1.2;
    return bmr * multiplier;
  }

  /// Daily calorie target based on goal
  static double calculateDailyCalories(double tdee, String goal) {
    final adjustment = AppConstants.goalCalorieAdjustment[goal] ?? 0;
    return tdee + adjustment;
  }

  /// Protein: 0.8–2.2g per kg depending on goal
  static double calculateProteinTarget(double weightKg, String goal) {
    double gPerKg;
    switch (goal) {
      case 'Build Muscle':
        gPerKg = 2.0;
        break;
      case 'Lose Weight':
        gPerKg = 1.6;
        break;
      case 'Gain Weight':
        gPerKg = 1.8;
        break;
      default:
        gPerKg = 1.2;
    }
    return weightKg * gPerKg;
  }

  /// Estimated weeks to reach goal weight
  static int estimateWeeksToGoal(double currentWeight, double goalWeight) {
    final diff = (currentWeight - goalWeight).abs();
    // ~0.5kg per week is safe rate
    return (diff / 0.5).ceil();
  }

  /// Macro split in calories
  static Map<String, double> calculateMacroCalories({
    required double totalCalories,
    required double proteinG,
  }) {
    final proteinCals = proteinG * 4;
    final remaining = totalCalories - proteinCals;
    final carbsCals = remaining * 0.55;
    final fatCals = remaining * 0.45;
    return {
      'protein': proteinCals,
      'carbs': carbsCals,
      'fat': fatCals,
    };
  }

  static double carbsFromCalories(double carbsCals) => carbsCals / 4;
  static double fatFromCalories(double fatCals) => fatCals / 9;
}

class HealthScoreCalculator {
  HealthScoreCalculator._();

  /// Proprietary health score 0–100
  static double calculate({
    required double protein,
    required double fiber,
    required double addedSugar,
    required double sodium,
    required double saturatedFat,
    required int additiveCount,
    required bool isUltraProcessed,
    required double calories,
  }) {
    double score = 50.0; // baseline

    // POSITIVE factors
    // Protein score (0–20 pts): >20g per serving is excellent
    final proteinScore = min(20.0, (protein / 20.0) * 20);
    score += proteinScore;

    // Fiber score (0–15 pts): >5g per serving is excellent
    final fiberScore = min(15.0, (fiber / 5.0) * 15);
    score += fiberScore;

    // NEGATIVE factors
    // Added sugar penalty (0–20 pts): >25g is max penalty
    final sugarPenalty = min(20.0, (addedSugar / 25.0) * 20);
    score -= sugarPenalty;

    // Sodium penalty (0–15 pts): >2300mg is max penalty
    final sodiumPenalty = min(15.0, (sodium / 2300.0) * 15);
    score -= sodiumPenalty;

    // Saturated fat penalty (0–10 pts): >20g is max penalty
    final satFatPenalty = min(10.0, (saturatedFat / 20.0) * 10);
    score -= satFatPenalty;

    // Additive penalty (0–10 pts): each additive costs 2 pts
    final additivePenalty = min(10.0, additiveCount * 2.0);
    score -= additivePenalty;

    // Ultra-processed penalty
    if (isUltraProcessed) score -= 10;

    return score.clamp(0, 100);
  }

  static String scoreLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Poor';
  }
}

class Formatters {
  Formatters._();

  static String formatCalories(double cals) => '${cals.round()} kcal';
  static String formatGrams(double g) => '${g.toStringAsFixed(1)}g';
  static String formatWeight(double kg) => '${kg.toStringAsFixed(1)} kg';
  static String formatWater(double liters) => '${(liters * 1000).round()} ml';
  static String formatScore(double score) => score.round().toString();
  static String formatPercent(double value) => '${(value * 100).round()}%';
}
