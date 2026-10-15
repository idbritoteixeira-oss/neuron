import 'package:shared_preferences/shared_preferences.dart';

import '../models/pigeon_models.dart';

abstract final class PigeonProfileStore {
  static String _key(String userId, String field) =>
      'pigeon.profile.$userId.$field';

  static Future<PigeonProfile> load(PigeonProfile fallback) async {
    final preferences = await SharedPreferences.getInstance();
    final savedAvatar = preferences.getString(_key(fallback.id, 'avatar'));
    return PigeonProfile(
      name: preferences.getString(_key(fallback.id, 'name')) ?? fallback.name,
      id: fallback.id,
      bio: preferences.getString(_key(fallback.id, 'bio')) ?? fallback.bio,
      isOnline: fallback.isOnline,
      verification: fallback.verification,
      avatarUrl: savedAvatar == null || savedAvatar.isEmpty
          ? fallback.avatarUrl
          : savedAvatar,
    );
  }

  static Future<void> save(PigeonProfile profile) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key(profile.id, 'name'), profile.name);
    await preferences.setString(_key(profile.id, 'bio'), profile.bio);
    final avatar = profile.avatarUrl?.trim() ?? '';
    if (avatar.isEmpty) {
      await preferences.remove(_key(profile.id, 'avatar'));
    } else {
      await preferences.setString(_key(profile.id, 'avatar'), avatar);
    }
  }
}
