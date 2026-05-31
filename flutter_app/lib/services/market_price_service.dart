import 'dart:convert';

import 'package:flutter_app/models/market_price_models.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:flutter_app/services/token_storage.dart';
import 'package:http/http.dart' as http;

class MarketPriceService {
  static const String _basePath = '/api/v1/ingredients/kamis-prices';

  static Future<Map<String, String>> _headers() async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = await TokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<List<IngredientPriceModel>> getAllPrices() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$_basePath/all');
    final response = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>;
      return data
          .map((e) => IngredientPriceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('시세 데이터를 불러오지 못했습니다.');
  }

  static Future<List<IngredientPriceModel>> getNaverShoppingPrices() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/ingredients/prices/all');
    final response = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>;
      return data
          .map((e) => IngredientPriceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('실시간 가격 데이터를 불러오지 못했습니다.');
  }
}
