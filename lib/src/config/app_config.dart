import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class AppConfig {
  // App display name used in the app shell and splash UI.
  static String appName = '';

  // WordPress API base domain, example: https://dashboard.your-site.com
  static String wpDomain = '';

  // WordPress username used for Application Password authentication.
  static String wpUser = '';

  // WordPress Application Password used for API authentication.
  static String wpAppPass = '';

  // App icon asset path or URL used for branding fallback.
  static String appIconPath = '';

  // App logo asset path or URL used on splash and brand screens.
  static String appLogoPath = '';

  // OneSignal app id for push notification integration.
  static String oneSignalAppId = '';

  // AdMob Android app id for ads initialization.
  static String admobAndroidAppId = '';

  // AdMob iOS app id for ads initialization.
  static String admobIosAppId = '';

  static Future<void> loadFromAsset({String path = 'app_config.json'}) async {
    try {
      final raw = await rootBundle.loadString(path);
      final json = jsonDecode(raw) as Map<String, dynamic>;

      appName = _readString(json, 'app_name');
      wpDomain = _readString(json, 'wp_domain');
      wpUser = _readString(json, 'wp_user');
      wpAppPass = _readString(json, 'wp_app_pass');

      final icon = _readString(json, 'app_icon_path');
      if (icon.isNotEmpty) {
        appIconPath = icon;
      }

      final logo = _readString(json, 'app_logo_path');
      if (logo.isNotEmpty) {
        appLogoPath = logo;
      }

      // Optional integration keys; keep empty if not provided.
      oneSignalAppId = _readString(json, 'oneSignalAppId');
      admobAndroidAppId = _readString(json, 'admobAndroidAppId');
      admobIosAppId = _readString(json, 'admobIosAppId');
    } catch (_) {
      // Keep empty defaults when config file is missing or invalid.
    }
  }

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return '';
  }
}
