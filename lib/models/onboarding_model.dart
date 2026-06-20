class OnboardingData {
  final String? name;
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final double? goalWeightKg;
  final String? activityLevel;

  /// Up to 3 goals the user picked, in selection order. The backend's
  /// calorie/macro math is built around a single primary goal, so
  /// [primaryGoal] (the first one picked) is what actually drives the
  /// numbers — the rest are just for personalization/display.
  final List<String> goals;
  final List<String> dietaryPreferences;
  final List<String> allergies;
  final double waterGoalLiters;

  const OnboardingData({
    this.name,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.goalWeightKg,
    this.activityLevel,
    this.goals = const [],
    this.dietaryPreferences = const [],
    this.allergies = const [],
    this.waterGoalLiters = 2.5,
  });

  String? get primaryGoal => goals.isNotEmpty ? goals.first : null;

  OnboardingData copyWith({
    String? name,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    double? goalWeightKg,
    String? activityLevel,
    List<String>? goals,
    List<String>? dietaryPreferences,
    List<String>? allergies,
    double? waterGoalLiters,
  }) {
    return OnboardingData(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goalWeightKg: goalWeightKg ?? this.goalWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goals: goals ?? this.goals,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      allergies: allergies ?? this.allergies,
      waterGoalLiters: waterGoalLiters ?? this.waterGoalLiters,
    );
  }

  bool get isComplete =>
      name != null &&
      name!.trim().isNotEmpty &&
      age != null &&
      gender != null &&
      heightCm != null &&
      weightKg != null &&
      goalWeightKg != null &&
      activityLevel != null &&
      goals.isNotEmpty;
}
