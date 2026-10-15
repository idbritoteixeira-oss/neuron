import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class PigeonNotificationSound {
  static const _enabledKey = 'pigeon.notification_sound.enabled';

  static Future<bool> isEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_enabledKey) ?? true;
  }

  static Future<void> setEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, enabled);
  }

  static Future<void> playPreview() => SystemSound.play(SystemSoundType.alert);
}
