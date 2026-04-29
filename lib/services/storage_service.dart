import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/alarm.dart';

class StorageService {
  static const String _key = 'alarms';

  Future<List<Alarm>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => Alarm.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveAlarms(List<Alarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(alarms.map((a) => a.toJson()).toList());
    await prefs.setString(_key, json);
  }
}
