import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final String menuName;
  final String ingredient;

  const CartItem({required this.menuName, required this.ingredient});

  String _toStorageString() =>
      jsonEncode({'menu': menuName, 'ingredient': ingredient});

  factory CartItem.fromStorageString(String s) {
    try {
      final map = jsonDecode(s) as Map<String, dynamic>;
      return CartItem(
        menuName: map['menu'] as String? ?? '',
        ingredient: map['ingredient'] as String? ?? s,
      );
    } catch (_) {
      // 구버전 호환: 단순 문자열이면 메뉴명 없이 처리
      return CartItem(menuName: '', ingredient: s);
    }
  }

  String get dedupKey => '$menuName\x1F$ingredient';
}

class CartService {
  static const _key = 'cart_items';

  static final itemCount = ValueNotifier<int>(0);

  static Future<List<CartItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final items = raw.map((s) => CartItem.fromStorageString(s)).toList();
    itemCount.value = items.length;
    return items;
  }

  static Future<void> addItems(
    List<String> ingredients, {
    required String menuName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final existing = raw.map(CartItem.fromStorageString).toList();
    final existingKeys = existing.map((e) => e.dedupKey).toSet();

    final toAdd = ingredients
        .map((ing) => CartItem(menuName: menuName, ingredient: ing))
        .where((item) => !existingKeys.contains(item.dedupKey))
        .toList();

    if (toAdd.isEmpty) return;

    final updated = [
      ...existing,
      ...toAdd,
    ].map((e) => e._toStorageString()).toList();

    await prefs.setStringList(_key, updated);
    itemCount.value = updated.length;
  }

  static Future<void> removeItem(CartItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final updated = raw
        .map(CartItem.fromStorageString)
        .where((e) => e.dedupKey != item.dedupKey)
        .map((e) => e._toStorageString())
        .toList();
    await prefs.setStringList(_key, updated);
    itemCount.value = updated.length;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    itemCount.value = 0;
  }
}
