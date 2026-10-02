import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  Future<String?> read(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);
  Future<void> write(String key, String value) async =>
      (await SharedPreferences.getInstance()).setString(key, value);
  Future<void> writeJson(String key, Object value) =>
      write(key, jsonEncode(value));
}
