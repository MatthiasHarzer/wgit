import 'dart:io';

import 'package:path_provider_android/path_provider_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';

/// Provides key-val-storage like functionalities with device storage and configurations
class ConfigService {
  static late SharedPreferences _prefs;

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

  }

}