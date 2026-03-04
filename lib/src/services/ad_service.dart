import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class AdService {
  Future<void> initialize() async {
    final appId = _platformAppId;
    if (appId.isEmpty) {
      return;
    }

    // AdMob integration point.
    // Initialize MobileAds using the platform-specific app id.
  }

  String get _platformAppId {
    if (kIsWeb) {
      return '';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AppConfig.admobAndroidAppId;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppConfig.admobIosAppId;
    }
    return '';
  }
}
