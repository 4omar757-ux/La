import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_city_state.dart';

/// حفظ/تحميل حالة اللعب الفردي محليًا لكل مدينة على حدة
class LocalSaveService {
  static String _key(String cityId) => 'citygame_state_$cityId';

  static Future<PlayerCityState> load(String cityId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(cityId));
    if (raw == null) return PlayerCityState();
    try {
      return PlayerCityState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return PlayerCityState();
    }
  }

  static Future<void> save(String cityId, PlayerCityState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(cityId), jsonEncode(state.toJson()));
  }

  static Future<void> reset(String cityId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(cityId));
  }
}
