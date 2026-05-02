import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RingtoneInfo {
  final String uri;
  final String title;
  const RingtoneInfo({required this.uri, required this.title});
}

class RingtoneService {
  static const _ch = MethodChannel('com.locatemeup/ringtone');
  static const _kUri = 'ringtone_uri';
  static const _kTitle = 'ringtone_title';

  RingtoneInfo? _selected;
  RingtoneInfo? get selected => _selected;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final uri = prefs.getString(_kUri);
    final title = prefs.getString(_kTitle);
    if (uri != null && title != null) {
      _selected = RingtoneInfo(uri: uri, title: title);
    }
  }

  /// Android: opens system ringtone picker.
  /// iOS: returns null — caller should use [getAvailableTones] + [select].
  Future<RingtoneInfo?> pick() async {
    if (!Platform.isAndroid) return null;
    try {
      final raw = await _ch.invokeMethod<Map<Object?, Object?>>('pickRingtone', {
        'currentUri': _selected?.uri,
      });
      if (raw == null) return null;
      final info = RingtoneInfo(
        uri: raw['uri']! as String,
        title: raw['title']! as String,
      );
      await _saveSelection(info);
      return info;
    } catch (_) {
      return null;
    }
  }

  /// iOS only: returns the list of preset tones.
  Future<List<RingtoneInfo>> getAvailableTones() async {
    if (!Platform.isIOS) return [];
    try {
      final raw = await _ch.invokeMethod<List<Object?>>('getAvailableTones');
      return (raw ?? []).map((e) {
        final m = e as Map<Object?, Object?>;
        return RingtoneInfo(uri: m['id'] as String, title: m['title'] as String);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> select(RingtoneInfo info) async {
    _selected = info;
    await _saveSelection(info);
  }

  Future<void> _saveSelection(RingtoneInfo info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUri, info.uri);
    await prefs.setString(_kTitle, info.title);
    _selected = info;
  }

  Future<void> play() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await _ch.invokeMethod<void>('playRingtone', {'uri': _selected?.uri});
    } catch (_) {}
  }

  Future<void> stop() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await _ch.invokeMethod<void>('stopRingtone');
    } catch (_) {}
  }
}
