// ignore_for_file: constant_identifier_names

import 'dart:io';

import 'package:path_provider_android/path_provider_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';

const _CURRENT_HOUSEHOLD_ID = "current_household";

/// Provides key-val-storage like functionalities with device storage and configurations
class ConfigService {
  static late SharedPreferences _prefs;

  static late String _currentHouseholdId;

  static Future<void> ensureInitialized() async {
    if (Platform.isAndroid) {
      SharedPreferencesAndroid.registerWith();
      PathProviderAndroid.registerWith();
    }

    _prefs = await SharedPreferences.getInstance();
    await _prefs.reload();
    await _load();
  }

  static Future<void> _load() async {
    _currentHouseholdId = _prefs.getString(_CURRENT_HOUSEHOLD_ID) ?? "";
  }

  /// The current household id saved between sessions
  static String get currentHouseholdId => _currentHouseholdId;

  static set currentHouseholdId(String id) {
    _prefs.setString(_CURRENT_HOUSEHOLD_ID, id);
    _currentHouseholdId = id;
  }
}
