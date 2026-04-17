import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  SharedPrefs._();

  static final SharedPrefs instance = SharedPrefs._();
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _store async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<String?> getString(String key) async {
    final prefs = await _store;
    return prefs.getString(key);
  }

  Future<int?> getInt(String key) async {
    final prefs = await _store;
    return prefs.getInt(key);
  }

  Future<bool?> getBool(String key) async {
    final prefs = await _store;
    return prefs.getBool(key);
  }

  Future<void> setString(String key, String value) async {
    final prefs = await _store;
    await prefs.setString(key, value);
  }

  Future<void> setInt(String key, int value) async {
    final prefs = await _store;
    await prefs.setInt(key, value);
  }

  Future<void> setBool(String key, bool value) async {
    final prefs = await _store;
    await prefs.setBool(key, value);
  }

  void resetForTests() {
    _prefs = null;
  }
}
