import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/scan_result_model.dart';
import '../models/user_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class ApiService {
  final http.Client _client;
  String? _authToken;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  void setAuthToken(String token) => _authToken = token;
  void clearAuthToken() => _authToken = null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

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

  // ─── Scan Food (Gemini + Open Food Facts pipeline) ──────────────────────────

  Future<ScanResultModel> scanFood({
    required String imageBase64,
    String? mealType,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/scan');
    final response = await _client
        .post(
          uri,
          headers: _headers,
          body: jsonEncode({
            'image_base64': imageBase64,
            'meal_type': mealType,
          }),
        )
        .timeout(const Duration(seconds: AppConstants.scanTimeoutSeconds));
    final json = await _handleResponse(response);
    return ScanResultModel.fromJson(json as Map<String, dynamic>);
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/auth/signup');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password, 'name': name}),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/auth/signin');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  // ─── User Profile ─────────────────────────────────────────────────────────

  Future<UserModel> getProfile() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/users/me');
    final response = await _client.get(uri, headers: _headers);
    final json = await _handleResponse(response);
    return UserModel.fromJson(json as Map<String, dynamic>);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> updates) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/users/me');
    final response = await _client.patch(
      uri,
      headers: _headers,
      body: jsonEncode(updates),
    );
    final json = await _handleResponse(response);
    return UserModel.fromJson(json as Map<String, dynamic>);
  }

  // ─── Food Logs ────────────────────────────────────────────────────────────

  Future<List<dynamic>> getFoodLogs({DateTime? date}) async {
    final query = date != null ? '?date=${date.toIso8601String().split('T')[0]}' : '';
    final uri = Uri.parse('${AppConstants.baseUrl}/food-logs$query');
    final response = await _client.get(uri, headers: _headers);
    return await _handleResponse(response) as List<dynamic>;
  }

  Future<Map<String, dynamic>> createFoodLog(Map<String, dynamic> log) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/food-logs');
    final response = await _client.post(uri, headers: _headers, body: jsonEncode(log));
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<void> deleteFoodLog(String id) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/food-logs/$id');
    final response = await _client.delete(uri, headers: _headers);
    await _handleResponse(response);
  }

  // ─── Weight Logs ──────────────────────────────────────────────────────────

  Future<List<dynamic>> getWeightLogs({int days = 30}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/weight-logs?days=$days');
    final response = await _client.get(uri, headers: _headers);
    return await _handleResponse(response) as List<dynamic>;
  }

  Future<Map<String, dynamic>> logWeight(double weightKg, {String? note}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/weight-logs');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({'weight_kg': weightKg, 'note': note}),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  // ─── Water Logs ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> logWater(double liters) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/water-logs');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({'amount_liters': liters}),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  // ─── AI Coach ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDailyReview() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/ai/daily-review');
    final response = await _client.get(uri, headers: _headers);
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> askCoach(String message) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/ai/coach/chat');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({'message': message}),
    );
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  // ─── Analytics ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getWeeklyReport() async {
    final uri = Uri.parse('${AppConstants.baseUrl}/analytics/weekly');
    final response = await _client.get(uri, headers: _headers);
    return await _handleResponse(response) as Map<String, dynamic>;
  }

  void dispose() => _client.close();
}
