// Weight Log
class WeightLogModel {
  final String id;
  final String userId;
  final double weightKg;
  final String? note;
  final DateTime loggedAt;

  const WeightLogModel({
    required this.id,
    required this.userId,
    required this.weightKg,
    this.note,
    required this.loggedAt,
  });

  factory WeightLogModel.fromJson(Map<String, dynamic> json) => WeightLogModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        weightKg: (json['weight_kg'] as num).toDouble(),
        note: json['note'] as String?,
        loggedAt: DateTime.parse(json['logged_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'weight_kg': weightKg,
        'note': note,
        'logged_at': loggedAt.toIso8601String(),
      };
}

// Water Log
class WaterLogModel {
  final String id;
  final String userId;
  final double amountLiters;
  final DateTime loggedAt;

  const WaterLogModel({
    required this.id,
    required this.userId,
    required this.amountLiters,
    required this.loggedAt,
  });

  factory WaterLogModel.fromJson(Map<String, dynamic> json) => WaterLogModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        amountLiters: (json['amount_liters'] as num).toDouble(),
        loggedAt: DateTime.parse(json['logged_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'amount_liters': amountLiters,
        'logged_at': loggedAt.toIso8601String(),
      };
}

// Step Log
class StepLogModel {
  final String id;
  final String userId;
  final int steps;
  final double distanceKm;
  final double caloriesBurned;
  final DateTime date;

  const StepLogModel({
    required this.id,
    required this.userId,
    required this.steps,
    required this.distanceKm,
    required this.caloriesBurned,
    required this.date,
  });

  factory StepLogModel.fromJson(Map<String, dynamic> json) => StepLogModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        steps: json['steps'] as int,
        distanceKm: (json['distance_km'] as num).toDouble(),
        caloriesBurned: (json['calories_burned'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'steps': steps,
        'distance_km': distanceKm,
        'calories_burned': caloriesBurned,
        'date': date.toIso8601String(),
      };
}

// Achievement
class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int xpReward;
  final bool isUnlocked;
  final double progress; // 0.0 to 1.0
  final DateTime? unlockedAt;
  final String category; // 'streak', 'scan', 'nutrition', 'weight', 'water'

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.xpReward,
    this.isUnlocked = false,
    this.progress = 0.0,
    this.unlockedAt,
    required this.category,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) => AchievementModel(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        icon: json['icon'] as String,
        xpReward: json['xp_reward'] as int,
        isUnlocked: json['is_unlocked'] as bool? ?? false,
        progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
        unlockedAt: json['unlocked_at'] != null
            ? DateTime.parse(json['unlocked_at'] as String)
            : null,
        category: json['category'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'icon': icon,
        'xp_reward': xpReward,
        'is_unlocked': isUnlocked,
        'progress': progress,
        'unlocked_at': unlockedAt?.toIso8601String(),
        'category': category,
      };
}

// AI Insight
class AiInsightModel {
  final String id;
  final String type; // 'daily', 'weekly', 'tip', 'alert'
  final String title;
  final String content;
  final String? actionLabel;
  final String? actionRoute;
  final DateTime createdAt;
  final bool isRead;

  const AiInsightModel({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    this.actionLabel,
    this.actionRoute,
    required this.createdAt,
    this.isRead = false,
  });

  factory AiInsightModel.fromJson(Map<String, dynamic> json) => AiInsightModel(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        actionLabel: json['action_label'] as String?,
        actionRoute: json['action_route'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        isRead: json['is_read'] as bool? ?? false,
      );
}
