class OnboardingData {
  final String? name;
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final double? goalWeightKg;
  final String? activityLevel;
  final String? goal;
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
    this.goal,
    this.dietaryPreferences = const [],
    this.allergies = const [],
    this.waterGoalLiters = 2.5,
  });

  OnboardingData copyWith({
    String? name,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    double? goalWeightKg,
    String? activityLevel,
    String? goal,
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
      goal: goal ?? this.goal,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      allergies: allergies ?? this.allergies,
      waterGoalLiters: waterGoalLiters ?? this.waterGoalLiters,
    );
  }

  bool get isComplete =>
      name != null &&
      age != null &&
      gender != null &&
      heightCm != null &&
      weightKg != null &&
      goalWeightKg != null &&
      activityLevel != null &&
      goal != null;
}
