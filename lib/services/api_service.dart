import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/scan_result_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

/// Thrown specifically on 401s so the app can route back to sign-in
/// rather than showing a generic error.
class UnauthorizedException extends ApiException {
  UnauthorizedException() : super('Session expired. Please sign in again.', 401);
}

class ApiService {
  final http.Client _client;
  final AuthService _authService;

  ApiService({http.Client? client, AuthService? authService})
      : _client = client ?? http.Client(),
        _authService = authService ?? AuthService();

  /// Fetches a fresh Firebase ID token on every request. Firebase
  /// caches and auto-refreshes the underlying token internally, so
  /// this is cheap and always correct — never store/reuse a token
  /// manually, since it expires after 1 hour.
  Future<Map<String, String>> _headers() async {
    final token = await _authService.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }
    final message = body is Map && body['detail'] != null
        ? body['detail'].toString()
        : 'Request failed';
    throw ApiException(message, response.statusCode);
  }

  // ─── Scan Food (Gemini + Open Food Facts pipeline) ──────────────────────────

  Future<ScanResultModel> scanFood({
    required String imageBase64,
    String? mealType,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/scan');
    final response = await _client
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({
            'image_base64': imageBase64,
            'meal_type': mealType,
          }),
        )
        .timeout(const Duration(seconds: AppConstants.scanTimeoutSeconds));
    final json = await _handleResponse(response);
    return ScanResultModel.fromJson(json as Map<String, dynamic>);
  }

  // ─── Onboarding ───────────────────────────────────────────────────────────

  Future<UserModel> completeOnboarding(Map<String, dynamic> onboardingData) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/users/onboarding');
    final response = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(onboardingData),
    );
    final json = await _handleResponse(response);
    return UserModel.fromJson(json as Map<String, dynamic>);
  }

  // ─── User Profile ─────────────────────────────────────────────────────────

  Future<UserModel> getProfile() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/users/me');
    final response = await _client.get(uri, headers: await _headers());
    final json = await _handleResponse(response);
    return UserModel.fromJson(json as Map<String, dynamic>);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> updates) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/users/me');
    final response = await _client.patch(
      uri,
      headers: await _headers(),
      body: jsonEncode(updates),
    );
    final json = await _handleResponse(response);
    return UserModel.fromJson(json as Map<String, dynamic>);
  }

  // ─── Food Logs ────────────────────────────────────────────────────────────

  Future<List<dynamic>> getFoodLogs({DateTime? date}) async {
    final query = date != null ? '?date=${date.toIso8601String().split('T')[0]}' : '';
    final uri = Uri.parse('${AppConstants.baseUrl}/food-logs$query');
    final response = await _client.get(uri, headers: await _headers());
    return await _handleResponse(response) as List<dynamic>;
  }

  Future<Map<String, dynamic>> createFoodLog(Map<String, dynamic> log) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/food-logs');
    final response = await _client.post(uri, headers: await _headers(), body: jsonEncode(log));
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<void> deleteFoodLog(String id) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/food-logs/$id');
    final response = await _client.delete(uri, headers: await _headers());
    await _handleResponse(response);
  }

  // ─── Weight Logs ──────────────────────────────────────────────────────────

  Future<List<dynamic>> getWeightLogs({int days = 30}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/weight-logs?days=$days');
    final response = await _client.get(uri, headers: await _headers());
    return await _handleResponse(response) as List<dynamic>;
  }

  Future<Map<String, dynamic>> logWeight(double weightKg, {String? note}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/weight-logs');
    final response = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'weight_kg': weightKg, 'note': note}),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  // ─── Water Logs ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> logWater(double liters) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/water-logs');
    final response = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'amount_liters': liters}),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTodayWater() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/water-logs/today');
    final response = await _client.get(uri, headers: await _headers());
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  // ─── Step Logs ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> syncSteps({
    required int steps,
    required double distanceKm,
    required double caloriesBurned,
    required DateTime date,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/step-logs/sync');
    final response = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'steps': steps,
        'distance_km': distanceKm,
        'calories_burned': caloriesBurned,
        'date': date.toIso8601String().split('T')[0],
      }),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  // ─── AI Coach ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDailyReview() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/ai/daily-review');
    final response = await _client.get(uri, headers: await _headers());
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<String> askCoach(String message) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/ai/coach/chat');
    final response = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'message': message}),
    );
    final json = await _handleResponse(response) as Map<String, dynamic>;
    return json['reply'] as String;
  }

  // ─── Analytics ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getWeeklyReport() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/analytics/weekly');
    final response = await _client.get(uri, headers: await _headers());
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  // ─── Achievements ─────────────────────────────────────────────────────────

  Future<List<dynamic>> getAchievements() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/achievements');
    final response = await _client.get(uri, headers: await _headers());
    return await _handleResponse(response) as List<dynamic>;
  }

  void dispose() => _client.close();
}
