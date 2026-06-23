import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tracking_models.dart';
import '../models/scan_result_model.dart';

// ─── Water Provider ────────────────────────────────────────────────────────────

final waterLogsProvider = StateNotifierProvider<WaterLogNotifier, List<WaterLogModel>>((ref) {
  return WaterLogNotifier();
});

class WaterLogNotifier extends StateNotifier<List<WaterLogModel>> {
  WaterLogNotifier() : super([]);

  void loadLogs(List<WaterLogModel> logs) {
    state = logs;
  }

  void addLog(WaterLogModel log) {
    state = [log, ...state];
  }

  void removeLog(String id) {
    state = state.where((l) => l.id != id).toList();
  }

  /// Optimistic add — creates a local placeholder until server confirms.
  WaterLogModel addWaterOptimistic(String userId, double liters) {
    final log = WaterLogModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      amountLiters: liters,
      loggedAt: DateTime.now(),
    );
    state = [log, ...state];
    return log;
  }

  void replaceLog(String tempId, WaterLogModel confirmed) {
    state = state.map((l) => l.id == tempId ? confirmed : l).toList();
  }

  double totalForDate(DateTime date) {
    return state
        .where((l) =>
            l.loggedAt.year == date.year &&
            l.loggedAt.month == date.month &&
            l.loggedAt.day == date.day)
        .fold(0.0, (sum, l) => sum + l.amountLiters);
  }

  List<WaterLogModel> logsForDate(DateTime date) {
    return state.where((l) =>
        l.loggedAt.year == date.year &&
        l.loggedAt.month == date.month &&
        l.loggedAt.day == date.day).toList();
  }
}

final todayWaterProvider = Provider<double>((ref) {
  return ref.watch(waterLogsProvider.notifier).totalForDate(DateTime.now());
});

final todayWaterLogsProvider = Provider<List<WaterLogModel>>((ref) {
  return ref.watch(waterLogsProvider.notifier).logsForDate(DateTime.now());
});

// ─── Weight Provider ───────────────────────────────────────────────────────────

final weightLogsProvider = StateNotifierProvider<WeightLogNotifier, List<WeightLogModel>>((ref) {
  return WeightLogNotifier();
});

class WeightLogNotifier extends StateNotifier<List<WeightLogModel>> {
  WeightLogNotifier() : super([]);

  void loadLogs(List<WeightLogModel> logs) {
    // Sort by date descending (newest first)
    final sorted = List<WeightLogModel>.from(logs)
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    state = sorted;
  }

  void addLog(WeightLogModel log) {
    state = [log, ...state];
  }

  void removeLog(String id) {
    state = state.where((l) => l.id != id).toList();
  }

  WeightLogModel? get latestLog => state.isEmpty ? null : state.first;

  List<WeightLogModel> get last30Days {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return state
        .where((l) => l.loggedAt.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }

  List<WeightLogModel> get chronological {
    return List<WeightLogModel>.from(state)
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }
}

final latestWeightProvider = Provider<WeightLogModel?>((ref) {
  return ref.watch(weightLogsProvider.notifier).latestLog;
});

// ─── Scan History Provider ─────────────────────────────────────────────────────

final scanHistoryProvider = StateNotifierProvider<ScanHistoryNotifier, List<ScanResultModel>>((ref) {
  return ScanHistoryNotifier();
});

class ScanHistoryNotifier extends StateNotifier<List<ScanResultModel>> {
  ScanHistoryNotifier() : super([]);

  void addScan(ScanResultModel result) {
    state = [result, ...state];
  }

  List<ScanResultModel> get recentScans => state.take(10).toList();
}

// ─── Step Provider ─────────────────────────────────────────────────────────────

final stepLogsProvider = StateNotifierProvider<StepLogNotifier, List<StepLogModel>>((ref) {
  return StepLogNotifier();
});

class StepLogNotifier extends StateNotifier<List<StepLogModel>> {
  StepLogNotifier() : super([]);

  void updateSteps(String userId, int steps) {
    final today = DateTime.now();
    final existing = state.where((l) =>
        l.date.year == today.year &&
        l.date.month == today.month &&
        l.date.day == today.day).toList();

    if (existing.isNotEmpty) {
      state = state.map((l) {
        if (l.id == existing.first.id) {
          return StepLogModel(
            id: l.id,
            userId: userId,
            steps: steps,
            distanceKm: steps * 0.00075,
            caloriesBurned: steps * 0.04,
            date: today,
          );
        }
        return l;
      }).toList();
    } else {
      state = [
        ...state,
        StepLogModel(
          id: today.millisecondsSinceEpoch.toString(),
          userId: userId,
          steps: steps,
          distanceKm: steps * 0.00075,
          caloriesBurned: steps * 0.04,
          date: today,
        ),
      ];
    }
  }

  StepLogModel? get todayLog {
    final today = DateTime.now();
    try {
      return state.firstWhere((l) =>
          l.date.year == today.year &&
          l.date.month == today.month &&
          l.date.day == today.day);
    } catch (_) {
      return null;
    }
  }
}

final todayStepsProvider = Provider<int>((ref) {
  return ref.watch(stepLogsProvider.notifier).todayLog?.steps ?? 0;
});

// ─── Achievements Provider ─────────────────────────────────────────────────────

final achievementsProvider = StateNotifierProvider<AchievementNotifier, List<AchievementModel>>((ref) {
  return AchievementNotifier();
});

class AchievementNotifier extends StateNotifier<List<AchievementModel>> {
  AchievementNotifier() : super(_defaultAchievements);

  void unlock(String id) {
    state = state.map((a) {
      if (a.id == id && !a.isUnlocked) {
        return AchievementModel(
          id: a.id, title: a.title, description: a.description,
          icon: a.icon, xpReward: a.xpReward,
          isUnlocked: true, progress: 1.0,
          unlockedAt: DateTime.now(), category: a.category,
        );
      }
      return a;
    }).toList();
  }

  void updateProgress(String id, double progress) {
    state = state.map((a) {
      if (a.id == id && !a.isUnlocked) {
        return AchievementModel(
          id: a.id, title: a.title, description: a.description,
          icon: a.icon, xpReward: a.xpReward,
          isUnlocked: false, progress: progress.clamp(0.0, 1.0),
          category: a.category,
        );
      }
      return a;
    }).toList();
  }
}

// ─── Nutrition Tip Provider ────────────────────────────────────────────────────

class NutritionTip {
  final String title;
  final String tip;
  NutritionTip({required this.title, required this.tip});
}

final nutritionTipProvider = StateNotifierProvider<NutritionTipNotifier, AsyncValue<NutritionTip>>((ref) {
  return NutritionTipNotifier();
});

class NutritionTipNotifier extends StateNotifier<AsyncValue<NutritionTip>> {
  NutritionTipNotifier() : super(const AsyncValue.loading());

  void setLoading() => state = const AsyncValue.loading();

  void setTip(String title, String tip) {
    state = AsyncValue.data(NutritionTip(title: title, tip: tip));
  }

  void setError(String msg) {
    state = AsyncValue.error(msg, StackTrace.current);
  }

  void setFallback() {
    state = AsyncValue.data(NutritionTip(
      title: 'Stay Consistent',
      tip: 'Scan and log your meals regularly to unlock personalised nutrition insights tailored to your goals.',
    ));
  }
}

const List<AchievementModel> _defaultAchievements = [
  AchievementModel(id: 'first_scan', title: 'First Scan!', description: 'Scan your first food item', icon: '🔍', xpReward: 50, category: 'scan'),
  AchievementModel(id: 'scan_10', title: 'Food Explorer', description: 'Scan 10 food items', icon: '🍽️', xpReward: 100, category: 'scan'),
  AchievementModel(id: 'scan_50', title: 'Nutrition Nerd', description: 'Scan 50 food items', icon: '🧪', xpReward: 250, category: 'scan'),
  AchievementModel(id: 'streak_7', title: 'Week Warrior', description: '7-day logging streak', icon: '🔥', xpReward: 200, category: 'streak'),
  AchievementModel(id: 'streak_30', title: 'Monthly Master', description: '30-day logging streak', icon: '🏆', xpReward: 500, category: 'streak'),
  AchievementModel(id: 'water_goal', title: 'Hydration Hero', description: 'Reach water goal 7 days in a row', icon: '💧', xpReward: 150, category: 'water'),
  AchievementModel(id: 'protein_goal', title: 'Protein Pro', description: 'Hit protein goal 5 days in a row', icon: '💪', xpReward: 150, category: 'nutrition'),
  AchievementModel(id: 'weight_log_10', title: 'Scale Tracker', description: 'Log weight 10 times', icon: '⚖️', xpReward: 100, category: 'weight'),
  AchievementModel(id: 'health_score_80', title: 'Clean Eater', description: 'Log a food with health score 80+', icon: '🥗', xpReward: 75, category: 'nutrition'),
  AchievementModel(id: 'steps_10k', title: '10K Steps', description: 'Walk 10,000 steps in a day', icon: '👟', xpReward: 100, category: 'streak'),
];
