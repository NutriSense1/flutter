import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/scan_result_model.dart';
import '../models/tracking_models.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class ApiTimeoutException implements Exception {
  @override
  String toString() => 'Request timed out';
}

class ApiService {
  final http.Client _client;
  final AuthService _authService;

  static const _timeout = Duration(seconds: AppConstants.requestTimeoutSeconds);

  ApiService({http.Client? client, AuthService? authService})
      : _client = client ?? http.Client(),
        _authService = authService ?? AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _get(Uri uri) async {
    return _wrap(_client.get(uri, headers: await _headers()));
  }

  Future<http.Response> _post(Uri uri, {Object? body}) async {
    return _wrap(_client.post(uri, headers: await _headers(), body: body));
  }

  Future<http.Response> _patch(Uri uri, {Object? body}) async {
    return _wrap(_client.patch(uri, headers: await _headers(), body: body));
  }

  Future<http.Response> _delete(Uri uri) async {
    return _wrap(_client.delete(uri, headers: await _headers()));
  }

  Future<http.Response> _wrap(Future<http.Response> request) async {
    try {
      return await request.timeout(_timeout);
    } on TimeoutException {
      throw ApiTimeoutException();
    }
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final message = body is Map && body['detail'] != null
        ? body['detail'].toString()
        : 'Request failed';
    throw ApiException(message, response.statusCode);
  }

  // ─── Scan Food ──────────────────────────────────────────────────────────────

  Future<ScanResultModel> scanFood({
    required String imageBase64,
    String? mealType,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/scan');
    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: await _headers(),
            body: jsonEncode({
              'image_base64': imageBase64,
              'meal_type': mealType,
            }),
          )
          .timeout(const Duration(seconds: AppConstants.scanTimeoutSeconds));
    } on TimeoutException {
      throw ApiTimeoutException();
    }
    final json = await _handleResponse(response);
    return ScanResultModel.fromJson(json as Map<String, dynamic>);
  }

  // ─── Onboarding ────────────────────────────────────────────────────────────

  Future<UserModel> completeOnboarding(Map<String, dynamic> onboardingData) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/users/onboarding');
    final response = await _post(uri, body: jsonEncode(onboardingData));
    final json = await _handleResponse(response);
    return UserModel.fromJson(json as Map<String, dynamic>);
  }

  // ─── User Profile ──────────────────────────────────────────────────────────

  Future<UserModel> getProfile() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/users/me');
    final response = await _get(uri);
    final json = await _handleResponse(response);
    return UserModel.fromJson(json as Map<String, dynamic>);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> updates) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/users/me');
    final response = await _patch(uri, body: jsonEncode(updates));
    final json = await _handleResponse(response);
    return UserModel.fromJson(json as Map<String, dynamic>);
  }

  /// Permanently deletes the account — Supabase rows (cascade) + Firebase Auth.
  /// Returns normally on 204. Throws [ApiException] on any other status.
  Future<void> deleteAccount() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/users/me');
    final response = await _delete(uri);
    if (response.statusCode != 204) {
      await _handleResponse(response); // will throw ApiException
    }
  }

  // ─── Food Logs ─────────────────────────────────────────────────────────────

  Future<List<dynamic>> getFoodLogs({DateTime? date}) async {
    final query = date != null ? '?date=${date.toIso8601String().split('T')[0]}' : '';
    final uri = Uri.parse('${AppConstants.baseUrl}/food-logs$query');
    final response = await _get(uri);
    return await _handleResponse(response) as List<dynamic>;
  }

  Future<Map<String, dynamic>> createFoodLog(Map<String, dynamic> log) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/food-logs');
    final response = await _post(uri, body: jsonEncode(log));
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<void> deleteFoodLog(String id) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/food-logs/$id');
    final response = await _delete(uri);
    await _handleResponse(response);
  }

  // ─── Weight Logs ───────────────────────────────────────────────────────────

  Future<List<WeightLogModel>> getWeightLogs({int days = 0}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/weight-logs?days=$days');
    final response = await _get(uri);
    final list = await _handleResponse(response) as List<dynamic>;
    return list.map((e) => WeightLogModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> logWeight(double weightKg, {String? note}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/weight-logs');
    final response = await _post(
      uri,
      body: jsonEncode({'weight_kg': weightKg, 'note': note}),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<void> deleteWeightLog(String id) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/weight-logs/$id');
    final response = await _delete(uri);
    if (response.statusCode != 204) await _handleResponse(response);
  }

  // ─── Water Logs ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> logWater(double liters) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/water-logs');
    final response = await _post(
      uri,
      body: jsonEncode({'amount_liters': liters}),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTodayWater() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/water-logs/today');
    final response = await _get(uri);
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<List<WaterLogModel>> getWaterLogs({String? date, int days = 7}) async {
    final query = date != null ? '?date=$date' : '?days=$days';
    final uri = Uri.parse('${AppConstants.baseUrl}/water-logs$query');
    final response = await _get(uri);
    final list = await _handleResponse(response) as List<dynamic>;
    return list.map((e) => WaterLogModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteWaterLog(String id) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/water-logs/$id');
    final response = await _delete(uri);
    if (response.statusCode != 204) await _handleResponse(response);
  }

  // ─── Step Logs ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> syncSteps({
    required int steps,
    required double distanceKm,
    required double caloriesBurned,
    required DateTime date,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/step-logs/sync');
    final response = await _post(
      uri,
      body: jsonEncode({
        'steps': steps,
        'distance_km': distanceKm,
        'calories_burned': caloriesBurned,
        'date': date.toIso8601String().split('T')[0],
      }),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  // ─── AI Coach ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDailyReview() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/ai/daily-review');
    final response = await _get(uri);
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getNutritionTip() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/ai/nutrition-tip');
    final response = await _get(uri);
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<String> askCoach(String message) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/ai/coach/chat');
    final response = await _post(uri, body: jsonEncode({'message': message}));
    final json = await _handleResponse(response) as Map<String, dynamic>;
    return json['reply'] as String;
  }

  // ─── Analytics ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getWeeklyReport() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/analytics/weekly');
    final response = await _get(uri);
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  // ─── Achievements ──────────────────────────────────────────────────────────

  Future<List<dynamic>> getAchievements() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/achievements');
    final response = await _get(uri);
    return await _handleResponse(response) as List<dynamic>;
  }

  // ─── Notifications / Push ──────────────────────────────────────────────────

  Future<void> registerDeviceToken(String token, String platform) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/notifications/device-token');
    final response = await _post(
      uri,
      body: jsonEncode({'token': token, 'platform': platform}),
    );
    await _handleResponse(response);
  }

  Future<void> removeDeviceToken(String token) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/notifications/device-token');
    final response = await _wrap(_client.delete(
      uri,
      headers: await _headers(),
      body: jsonEncode({'token': token}),
    ));
    if (response.statusCode != 204) await _handleResponse(response);
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/notifications/preferences');
    final response = await _get(uri);
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateNotificationPreferences(
      Map<String, bool> updates) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/notifications/preferences');
    final response = await _patch(uri, body: jsonEncode(updates));
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getNotifications({int limit = 50}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/notifications?limit=$limit');
    final response = await _get(uri);
    return await _handleResponse(response) as List<dynamic>;
  }

  Future<void> markAllNotificationsRead() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/notifications/read-all');
    final response = await _post(uri);
    await _handleResponse(response);
  }

  Future<Map<String, dynamic>> sendTestPush() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/notifications/test-push');
    final response = await _post(uri);
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  void dispose() => _client.close();
}
