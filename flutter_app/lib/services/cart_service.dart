import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartService {
  static const _key = 'cart_items';

  static final itemCount = ValueNotifier<int>(0);

  static Future<List<String>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_key) ?? [];
    itemCount.value = items.length;
    return items;
  }

  static Future<void> addItems(List<String> newItems) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    final updated = {...current, ...newItems}.toList();
    await prefs.setStringList(_key, updated);
    itemCount.value = updated.length;
  }

  static Future<void> removeItem(String item) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    current.remove(item);
    await prefs.setStringList(_key, current);
    itemCount.value = current.length;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    itemCount.value = 0;
  }
}
