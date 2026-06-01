import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class PriceAlertService {
  static Future<void> registerToken(String? jwt) async {
    if (jwt == null || jwt.isEmpty) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({'fcmToken': token, 'platform': 'ios'}),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('FCM 토큰 등록 실패: $e');
    }
  }

  static Future<bool> follow(int ingredientId, String? jwt) async {
    if (jwt == null || jwt.isEmpty) return false;
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/alerts/$ingredientId'),
        headers: {'Authorization': 'Bearer $jwt'},
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      return body['success'] == true;
    } catch (e) {
      debugPrint('알림 팔로우 실패: $e');
      return false;
    }
  }

  static Future<bool> unfollow(int ingredientId, String? jwt) async {
    if (jwt == null || jwt.isEmpty) return false;
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/alerts/$ingredientId'),
        headers: {'Authorization': 'Bearer $jwt'},
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      return body['success'] == true;
    } catch (e) {
      debugPrint('알림 팔로우 해제 실패: $e');
      return false;
    }
  }

  static Future<bool> isFollowing(int ingredientId, String? jwt) async {
    if (jwt == null || jwt.isEmpty) return false;
    try {
      final res = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/notifications/alerts/$ingredientId/status'),
        headers: {'Authorization': 'Bearer $jwt'},
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      return body['following'] == true;
    } catch (e) {
      debugPrint('알림 상태 조회 실패: $e');
      return false;
    }
  }
}
