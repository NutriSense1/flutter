import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/onboarding_model.dart';
import '../core/utils/nutrition_calculator.dart';

// Simulates local user state (replace with real auth/storage service)
final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier() : super(null);

  void setUser(UserModel user) => state = user;

  void clearUser() => state = null;

  void updateWeight(double newWeight) {
    if (state == null) return;
    state = state!.copyWith(weightKg: newWeight);
  }

  void addXP(int xp) {
    if (state == null) return;
    final newXp = state!.xp + xp;
    final newLevel = _calculateLevel(newXp);
    state = state!.copyWith(xp: newXp, level: newLevel);
  }

  void incrementStreak() {
    if (state == null) return;
    state = state!.copyWith(currentStreak: state!.currentStreak + 1);
  }

  void resetStreak() {
    if (state == null) return;
    state = state!.copyWith(currentStreak: 0);
  }

  int _calculateLevel(int xp) {
    // Level thresholds: 100, 250, 500, 1000, 2000...
    if (xp < 100) return 1;
    if (xp < 250) return 2;
    if (xp < 500) return 3;
    if (xp < 1000) return 4;
    if (xp < 2000) return 5;
    if (xp < 4000) return 6;
    if (xp < 7000) return 7;
    if (xp < 11000) return 8;
    if (xp < 16000) return 9;
    return 10;
  }

  UserModel createFromOnboarding(OnboardingData data, String id, String email) {
    final bmr = NutritionCalculator.calculateBMR(
      weightKg: data.weightKg!,
      heightCm: data.heightCm!,
      age: data.age!,
      gender: data.gender!,
    );
    final tdee = NutritionCalculator.calculateTDEE(bmr, data.activityLevel!);
    final dailyCalories = NutritionCalculator.calculateDailyCalories(tdee, data.primaryGoal!);
    final dailyProtein = NutritionCalculator.calculateProteinTarget(data.weightKg!, data.primaryGoal!);
    final macros = NutritionCalculator.calculateMacroCalories(
      totalCalories: dailyCalories,
      proteinG: dailyProtein,
    );

    final user = UserModel(
      id: id,
      name: data.name!,
      email: email,
      age: data.age!,
      gender: data.gender!,
      heightCm: data.heightCm!,
      weightKg: data.weightKg!,
      goalWeightKg: data.goalWeightKg!,
      activityLevel: data.activityLevel!,
      goal: data.primaryGoal!,
      dietaryPreferences: data.dietaryPreferences,
      allergies: data.allergies,
      waterGoalLiters: data.waterGoalLiters,
      dailyCalorieTarget: dailyCalories,
      dailyProteinTarget: dailyProtein,
      dailyCarbsTarget: NutritionCalculator.carbsFromCalories(macros['carbs']!),
      dailyFatTarget: NutritionCalculator.fatFromCalories(macros['fat']!),
      createdAt: DateTime.now(),
    );
    state = user;
    return user;
  }
}

// Onboarding state provider
final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingData>((ref) {
  return OnboardingNotifier();
});

class OnboardingNotifier extends StateNotifier<OnboardingData> {
  OnboardingNotifier() : super(const OnboardingData());

  void updateName(String name) => state = state.copyWith(name: name);
  void updateAge(int age) => state = state.copyWith(age: age);
  void updateGender(String gender) => state = state.copyWith(gender: gender);
  void updateHeight(double height) => state = state.copyWith(heightCm: height);
  void updateWeight(double weight) => state = state.copyWith(weightKg: weight);
  void updateGoalWeight(double goalWeight) => state = state.copyWith(goalWeightKg: goalWeight);
  void updateActivityLevel(String level) => state = state.copyWith(activityLevel: level);

  /// Toggles a goal on/off. Capped at 3 selections — the first one picked
  /// becomes the "primary" goal used for calorie/macro math, the rest are
  /// kept for personalization. The UI also enforces the cap (and tells the
  /// user why), this is just a safety net.
  void toggleGoal(String goal) {
    final list = List<String>.from(state.goals);
    if (list.contains(goal)) {
      list.remove(goal);
    } else {
      if (list.length >= 3) return;
      list.add(goal);
    }
    state = state.copyWith(goals: list);
  }

  void updateWaterGoal(double liters) => state = state.copyWith(waterGoalLiters: liters);

  void toggleDietaryPreference(String pref) {
    final prefs = List<String>.from(state.dietaryPreferences);
    if (prefs.contains(pref)) {
      prefs.remove(pref);
    } else {
      prefs.add(pref);
    }
    state = state.copyWith(dietaryPreferences: prefs);
  }

  void toggleAllergen(String allergen) {
    final list = List<String>.from(state.allergies);
    if (list.contains(allergen)) {
      list.remove(allergen);
    } else {
      list.add(allergen);
    }
    state = state.copyWith(allergies: list);
  }

  void reset() => state = const OnboardingData();
}

// Onboarding page index provider
final onboardingPageProvider = StateProvider<int>((ref) => 0);
