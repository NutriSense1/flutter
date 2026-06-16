import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

/// Service for looking up packaged food products via barcode using
/// the Open Food Facts public API.
class OpenFoodFactsService {
  final http.Client _client;
  OpenFoodFactsService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>?> lookupByBarcode(String barcode) async {
    final uri = Uri.parse('${AppConstants.openFoodFactsUrl}/product/$barcode.json');
    final response = await _client.get(uri);
    if (response.statusCode != 200) return null;
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['status'] != 1) return null;
    return json['product'] as Map<String, dynamic>?;
  }

  Future<List<Map<String, dynamic>>> searchByName(String name, {int limit = 10}) async {
    final uri = Uri.parse(
      '${AppConstants.openFoodFactsUrl.replaceFirst('/api/v3', '')}/cgi/search.pl'
      '?search_terms=${Uri.encodeComponent(name)}&search_simple=1&action=process&json=1&page_size=$limit',
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) return [];
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final products = json['products'] as List<dynamic>? ?? [];
    return products.cast<Map<String, dynamic>>();
  }

  /// Extracts normalized nutrition data (per 100g) from an OFF product payload.
  Map<String, dynamic> extractNutrition(Map<String, dynamic> product) {
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};
    return {
      'calories': (nutriments['energy-kcal_100g'] as num?)?.toDouble() ?? 0,
      'protein': (nutriments['proteins_100g'] as num?)?.toDouble() ?? 0,
      'carbs': (nutriments['carbohydrates_100g'] as num?)?.toDouble() ?? 0,
      'fat': (nutriments['fat_100g'] as num?)?.toDouble() ?? 0,
      'fiber': (nutriments['fiber_100g'] as num?)?.toDouble() ?? 0,
      'sugar': (nutriments['sugars_100g'] as num?)?.toDouble() ?? 0,
      'sodium': ((nutriments['sodium_100g'] as num?)?.toDouble() ?? 0) * 1000, // g -> mg
      'saturated_fat': (nutriments['saturated-fat_100g'] as num?)?.toDouble() ?? 0,
      'additives': List<String>.from(product['additives_tags'] ?? []),
      'allergens': List<String>.from(product['allergens_tags'] ?? []),
      'nova_group': product['nova_group'] as int?, // 1-4, 4 = ultra-processed
      'ingredients_text': product['ingredients_text'] as String? ?? '',
    };
  }

  void dispose() => _client.close();
}
