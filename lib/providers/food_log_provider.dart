import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_log_model.dart';
import '../models/scan_result_model.dart';

// Selected diary date
final diaryDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Food logs for selected date (mock in-memory store, replace with repository)
final foodLogsProvider = StateNotifierProvider<FoodLogNotifier, List<FoodLogModel>>((ref) {
  return FoodLogNotifier();
});

class FoodLogNotifier extends StateNotifier<List<FoodLogModel>> {
  FoodLogNotifier() : super([]);

  void addFromScan(ScanResultModel scan, String mealType, String userId, {double servings = 1.0}) {
    final log = FoodLogModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      productName: scan.productName,
      brand: scan.brand,
      imageUrl: scan.imageUrl,
      mealType: mealType,
      servingSize: scan.servingSize,
      servingUnit: scan.servingUnit,
      servingsConsumed: servings,
      nutritionInfo: scan.nutritionInfo,
      healthScore: scan.healthScore,
      scanId: scan.id,
      loggedAt: DateTime.now(),
    );
    state = [...state, log];
  }

  void removeLog(String id) {
    state = state.where((l) => l.id != id).toList();
  }

  /// Add a food log entry created directly from the AI Coach (no scan).
  void addFromChat(FoodLogModel log) {
    state = [log, ...state];
  }

  void updateServings(String id, double servings) {
    state = state.map((l) => l.id == id
        ? FoodLogModel(
            id: l.id,
            userId: l.userId,
            productName: l.productName,
            brand: l.brand,
            imageUrl: l.imageUrl,
            mealType: l.mealType,
            servingSize: l.servingSize,
            servingUnit: l.servingUnit,
            servingsConsumed: servings,
            nutritionInfo: l.nutritionInfo,
            healthScore: l.healthScore,
            scanId: l.scanId,
            loggedAt: l.loggedAt,
          )
        : l).toList();
  }

  List<FoodLogModel> logsForDate(DateTime date) {
    return state.where((l) =>
        l.loggedAt.year == date.year &&
        l.loggedAt.month == date.month &&
        l.loggedAt.day == date.day).toList();
  }

  List<FoodLogModel> logsForMeal(DateTime date, String mealType) {
    return logsForDate(date).where((l) => l.mealType == mealType).toList();
  }
}

// Derived providers
final todayLogsProvider = Provider<List<FoodLogModel>>((ref) {
  final notifier = ref.watch(foodLogsProvider.notifier);
  return notifier.logsForDate(DateTime.now());
});

final todaySummaryProvider = Provider<DailySummary>((ref) {
  final logs = ref.watch(todayLogsProvider);
  return DailySummary.fromLogs(DateTime.now(), logs);
});

final caloriesConsumedTodayProvider = Provider<double>((ref) {
  return ref.watch(todaySummaryProvider).totalCalories;
});
