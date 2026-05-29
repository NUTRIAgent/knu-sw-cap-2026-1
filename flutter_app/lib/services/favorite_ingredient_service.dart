import 'dart:convert';

import 'package:flutter_app/services/auth_service.dart';
import 'package:flutter_app/services/token_storage.dart';
import 'package:http/http.dart' as http;

class FavoriteIngredientService {
  static const String _basePath = '/api/v1/ingredients/favorites';

  static Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Set<int>> getFavoriteIds() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/ids');
    final response = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>;
      return data.map((e) => e as int).toSet();
    }
    return {};
  }

  static Future<void> addFavorite(int ingredientId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/$ingredientId');
    await http
        .post(uri, headers: await _headers())
        .timeout(const Duration(seconds: 10));
  }

  static Future<void> removeFavorite(int ingredientId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/$ingredientId');
    await http
        .delete(uri, headers: await _headers())
        .timeout(const Duration(seconds: 10));
  }
}
