import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class PriceAlertService {
  static Future<void> registerToken(String? jwt) async {
    if (jwt == null || jwt.isEmpty) return;
    try {
      if (Platform.isIOS) {
        String? apnsToken;
        for (int i = 0; i < 5; i++) {
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (apnsToken != null) break;
          await Future.delayed(const Duration(seconds: 1));
        }
        if (apnsToken == null) {
          debugPrint('APNs 토큰 미준비 — FCM 토큰 등록 스킵');
          return;
        }
      }
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

  static Future<bool> follow(
      String kamisItemCode, String kamisItemName, String? jwt) async {
    if (jwt == null || jwt.isEmpty) return false;
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/alerts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'kamisItemCode': kamisItemCode,
          'kamisItemName': kamisItemName,
        }),
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      return body['success'] == true;
    } catch (e) {
      debugPrint('알림 팔로우 실패: $e');
      return false;
    }
  }

  static Future<bool> unfollow(String kamisItemCode, String? jwt) async {
    if (jwt == null || jwt.isEmpty) return false;
    try {
      final res = await http.delete(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/notifications/alerts/${Uri.encodeComponent(kamisItemCode)}'),
        headers: {'Authorization': 'Bearer $jwt'},
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      return body['success'] == true;
    } catch (e) {
      debugPrint('알림 팔로우 해제 실패: $e');
      return false;
    }
  }

  static Future<bool> isFollowing(String kamisItemCode, String? jwt) async {
    if (jwt == null || jwt.isEmpty) return false;
    try {
      final res = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/notifications/alerts/${Uri.encodeComponent(kamisItemCode)}/status'),
        headers: {'Authorization': 'Bearer $jwt'},
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      return body['following'] == true;
    } catch (e) {
      debugPrint('알림 상태 조회 실패: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getMyAlerts(String? jwt) async {
    if (jwt == null || jwt.isEmpty) return [];
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/alerts'),
        headers: {'Authorization': 'Bearer $jwt'},
      ).timeout(const Duration(seconds: 10));
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body['success'] != true || body['data'] == null) return [];
      return List<Map<String, dynamic>>.from(body['data']);
    } catch (e) {
      debugPrint('알림 목록 조회 실패: $e');
      return [];
    }
  }
}
