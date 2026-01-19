import 'package:shared_preferences/shared_preferences.dart';

/// Internal storage helper for Dev Tools
class DevToolsPreferences {
  static SharedPreferences? _prefs;

  /// Initialize instances
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save data based on type
  static Future<bool> saveData({
    required String key,
    required dynamic value,
  }) async {
    if (_prefs == null) await init();

    if (value is String) return await _prefs!.setString(key, value);
    if (value is int) return await _prefs!.setInt(key, value);
    if (value is bool) return await _prefs!.setBool(key, value);
    if (value is double) return await _prefs!.setDouble(key, value);
    if (value is List<String>) return await _prefs!.setStringList(key, value);

    return false;
  }

  /// Get data (returns dynamic, cast as needed)
  static dynamic getData({required String key}) {
    // If init hasn't run yet, this might return null or throw.
    // Ideally init() is called in DevToolsConfig.init()
    return _prefs?.get(key);
  }

  static Future<bool> remove({required String key}) async {
    if (_prefs == null) await init();
    return await _prefs!.remove(key);
  }
}
