import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class AppConfig {
  static String wpDomain = '';
  static String wpUser = '';
  static String wpAppPass = '';
  static String oneSignalAppId = '';
  static String admobAndroidAppId = '';
  static String admobIosAppId = '';

  // Compile-time overrides:
  // flutter run --dart-define=WP_DOMAIN=... --dart-define=WP_USER=... --dart-define=WP_APP_PASS=...
  static const _envWpDomain = String.fromEnvironment('WP_DOMAIN');
  static const _envWpUser = String.fromEnvironment('WP_USER');
  static const _envWpAppPass = String.fromEnvironment('WP_APP_PASS');
  static const _envOneSignalAppId = String.fromEnvironment('ONESIGNAL_APP_ID');
  static const _envAdmobAndroidAppId = String.fromEnvironment(
    'ADMOB_ANDROID_APP_ID',
  );
  static const _envAdmobIosAppId = String.fromEnvironment('ADMOB_IOS_APP_ID');

  static Future<void> loadFromAsset({String path = 'app_config.json'}) async {
    try {
      final raw = await rootBundle.loadString(path);
      final json = jsonDecode(raw) as Map<String, dynamic>;

      wpDomain = _readString(json, [
        'wp_domain',
        'WP_DOMAIN',
        'wpDomain',
        'wpBaseUrl',
        'WP_BASE_URL',
        'domain',
        'DOMAIN',
      ]);
      wpUser = _readString(json, [
        'wp_user',
        'WP_USER',
        'wpUsername',
        'WP_USERNAME',
      ]);
      wpAppPass = _readString(json, [
        'wp_app_pass',
        'WP_APP_PASS',
        'wpAppPassword',
        'WP_APP_PASSWORD',
      ]);
      oneSignalAppId = _readString(json, [
        'oneSignalAppId',
        'ONESIGNAL_APP_ID',
      ]);
      admobAndroidAppId = _readString(json, [
        'admobAndroidAppId',
        'ADMOB_ANDROID_APP_ID',
      ]);
      admobIosAppId = _readString(json, ['admobIosAppId', 'ADMOB_IOS_APP_ID']);
    } catch (_) {
      // Keep empty defaults when config file is missing or invalid.
    }

    // Apply secure build-time overrides last.
    wpDomain = _envWpDomain.isNotEmpty ? _envWpDomain.trim() : wpDomain;
    wpUser = _envWpUser.isNotEmpty ? _envWpUser.trim() : wpUser;
    wpAppPass = _envWpAppPass.isNotEmpty ? _envWpAppPass.trim() : wpAppPass;
    oneSignalAppId = _envOneSignalAppId.isNotEmpty
        ? _envOneSignalAppId.trim()
        : oneSignalAppId;
    admobAndroidAppId = _envAdmobAndroidAppId.isNotEmpty
        ? _envAdmobAndroidAppId.trim()
        : admobAndroidAppId;
    admobIosAppId = _envAdmobIosAppId.isNotEmpty
        ? _envAdmobIosAppId.trim()
        : admobIosAppId;
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }
}
