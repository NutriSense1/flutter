class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final int age;
  final String gender;
  final double heightCm;
  final double weightKg;
  final double goalWeightKg;
  final String activityLevel;
  final String goal;
  final List<String> dietaryPreferences;
  final List<String> allergies;
  final double waterGoalLiters;
  final double dailyCalorieTarget;
  final double dailyProteinTarget;
  final double dailyCarbsTarget;
  final double dailyFatTarget;
  final bool isPremium;
  final int totalScans;
  final int xp;
  final int level;
  final int currentStreak;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.goalWeightKg,
    required this.activityLevel,
    required this.goal,
    required this.dietaryPreferences,
    required this.allergies,
    required this.waterGoalLiters,
    required this.dailyCalorieTarget,
    required this.dailyProteinTarget,
    required this.dailyCarbsTarget,
    required this.dailyFatTarget,
    this.isPremium = false,
    this.totalScans = 0,
    this.xp = 0,
    this.level = 1,
    this.currentStreak = 0,
    required this.createdAt,
  });

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  String get bmiCategory {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    double? weightKg,
    double? goalWeightKg,
    String? activityLevel,
    String? goal,
    List<String>? dietaryPreferences,
    List<String>? allergies,
    double? waterGoalLiters,
    double? dailyCalorieTarget,
    double? dailyProteinTarget,
    double? dailyCarbsTarget,
    double? dailyFatTarget,
    bool? isPremium,
    int? totalScans,
    int? xp,
    int? level,
    int? currentStreak,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      age: age,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg ?? this.weightKg,
      goalWeightKg: goalWeightKg ?? this.goalWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      allergies: allergies ?? this.allergies,
      waterGoalLiters: waterGoalLiters ?? this.waterGoalLiters,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      dailyProteinTarget: dailyProteinTarget ?? this.dailyProteinTarget,
      dailyCarbsTarget: dailyCarbsTarget ?? this.dailyCarbsTarget,
      dailyFatTarget: dailyFatTarget ?? this.dailyFatTarget,
      isPremium: isPremium ?? this.isPremium,
      totalScans: totalScans ?? this.totalScans,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      currentStreak: currentStreak ?? this.currentStreak,
      createdAt: createdAt,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        avatarUrl: json['avatar_url'] as String?,
        age: json['age'] as int,
        gender: json['gender'] as String,
        heightCm: (json['height_cm'] as num).toDouble(),
        weightKg: (json['weight_kg'] as num).toDouble(),
        goalWeightKg: (json['goal_weight_kg'] as num).toDouble(),
        activityLevel: json['activity_level'] as String,
        goal: json['goal'] as String,
        dietaryPreferences: List<String>.from(json['dietary_preferences'] ?? []),
        allergies: List<String>.from(json['allergies'] ?? []),
        waterGoalLiters: (json['water_goal_liters'] as num).toDouble(),
        dailyCalorieTarget: (json['daily_calorie_target'] as num).toDouble(),
        dailyProteinTarget: (json['daily_protein_target'] as num).toDouble(),
        dailyCarbsTarget: (json['daily_carbs_target'] as num).toDouble(),
        dailyFatTarget: (json['daily_fat_target'] as num).toDouble(),
        isPremium: json['is_premium'] as bool? ?? false,
        totalScans: json['total_scans'] as int? ?? 0,
        xp: json['xp'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        currentStreak: json['current_streak'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
        'age': age,
        'gender': gender,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'goal_weight_kg': goalWeightKg,
        'activity_level': activityLevel,
        'goal': goal,
        'dietary_preferences': dietaryPreferences,
        'allergies': allergies,
        'water_goal_liters': waterGoalLiters,
        'daily_calorie_target': dailyCalorieTarget,
        'daily_protein_target': dailyProteinTarget,
        'daily_carbs_target': dailyCarbsTarget,
        'daily_fat_target': dailyFatTarget,
        'is_premium': isPremium,
        'total_scans': totalScans,
        'xp': xp,
        'level': level,
        'current_streak': currentStreak,
        'created_at': createdAt.toIso8601String(),
      };
}
