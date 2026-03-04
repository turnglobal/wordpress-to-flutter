import '../config/app_config.dart';

class NotificationService {
  Future<void> initialize() async {
    if (AppConfig.oneSignalAppId.isEmpty) {
      return;
    }

    // OneSignal integration point.
    // Initialize SDK with AppConfig.oneSignalAppId for both Android and iOS.
  }
}
