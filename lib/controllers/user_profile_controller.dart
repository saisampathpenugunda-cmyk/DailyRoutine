import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller for managing the user profile name, reactive notifications,
/// and permanent persistence across app launches.
class UserProfileController extends ValueNotifier<String> {
  static const String defaultUserName = 'Sampath';
  static const String prefsKey = 'user_profile_name';

  final SharedPreferences? _prefs;

  UserProfileController([
    super.value = defaultUserName,
    this._prefs,
  ]);

  /// Current user display name.
  String get userName => value;

  /// Asynchronously initializes [UserProfileController] by loading the saved
  /// name from [SharedPreferences], falling back to [defaultUserName].
  static Future<UserProfileController> init([SharedPreferences? prefs]) async {
    final preferences = prefs ?? await SharedPreferences.getInstance();
    final savedName = preferences.getString(prefsKey);
    final name = (savedName != null && savedName.trim().isNotEmpty)
        ? savedName.trim()
        : defaultUserName;
    return UserProfileController(name, preferences);
  }

  /// Updates the user name, notifies listeners, and persists to [SharedPreferences].
  Future<void> setUserName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    value = trimmed;
    if (_prefs != null) {
      await _prefs.setString(prefsKey, trimmed);
    }
  }
}
