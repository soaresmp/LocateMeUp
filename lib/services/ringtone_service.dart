import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
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

  final AudioPlayer _fallback = AudioPlayer();

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
      _selected = info;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUri, info.uri);
      await prefs.setString(_kTitle, info.title);
      return info;
    } catch (_) {
      return null;
    }
  }

  Future<void> play() async {
    if (Platform.isAndroid) {
      try {
        await _ch.invokeMethod<void>('playRingtone', {'uri': _selected?.uri});
        return;
      } catch (_) {}
    }
    await _fallback.play(AssetSource('wakeup.mp3'));
  }

  Future<void> stop() async {
    if (Platform.isAndroid) {
      try {
        await _ch.invokeMethod<void>('stopRingtone');
      } catch (_) {}
    }
    await _fallback.stop();
  }

  void dispose() => _fallback.dispose();
}
