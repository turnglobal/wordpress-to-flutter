# WordPress to Flutter App (WP2F)

A production-ready **WordPress to Flutter app template** for **Android and iOS**, built with **Flutter Material 3**.  
This project consumes the WordPress REST API and includes modern UX patterns, category browsing, search, comments, sharing, offline cache mode, and integration hooks for OneSignal, AdMob, and deep links.

Keywords: WordPress Flutter app, WordPress API Flutter, Flutter news app, Android iOS WordPress app, Material 3 Flutter template.

## App Preview

![WordPress to Flutter app preview](https://i.imgur.com/5QIwXpn.png)

## Credits

- Fully developed by **Chandima Galahitiyawa**
- Funded by **Turn.Global** for the community
- Licensed under **GNU GPL v3.0** (see [LICENSE](LICENSE))

## Features

- WordPress REST API integration with Application Password support
- Latest posts with infinite scroll
- Featured posts slider
- Category filters and category-based post listing
- Search posts by keyword
- Post details with author/date/category metadata
- Embedded media support (video + allowed embed sources)
- WordPress comments read + submit
- Related posts from same category
- Share posts
- Light / Dark / System theme
- Offline cache mode + clear cache action
- Integration hooks for OneSignal, AdMob, and dynamic deep links

## Tech Stack

- Flutter (Material 3)
- Provider state management
- `http` for API calls
- `shared_preferences` for app state/cache
- `flutter_secure_storage` for sensitive local values

## Project Structure

- `lib/src/config/` app configuration loading
- `lib/src/services/` API, cache, integrations
- `lib/src/repositories/` repository layer
- `lib/src/viewmodels/` view models
- `lib/src/screens/` app screens
- `lib/src/widgets/` reusable UI widgets

## Configuration

### 1. Use the example file

Copy `app_config.example.json` to `app_config.json`.

### 2. Update `app_config.json`

`app_config.json` is loaded at app startup and used globally.

Required keys:

- `wp_domain`
- `wp_user`
- `wp_app_pass`

Optional keys:

- `oneSignalAppId`
- `admobAndroidAppId`
- `admobIosAppId`

Example:

```json
{
  "wp_domain": "https://dashboard.your-site.com",
  "wp_user": "your_wp_username",
  "wp_app_pass": "xxxx xxxx xxxx xxxx xxxx xxxx",
  "oneSignalAppId": "your_onesignal_app_id",
  "admobAndroidAppId": "ca-app-pub-xxxxxxxxxxxxxxxx~xxxxxxxxxx",
  "admobIosAppId": "ca-app-pub-xxxxxxxxxxxxxxxx~xxxxxxxxxx"
}
```

## Setup

1. Install dependencies:
   - `flutter pub get`
2. Configure:
   - copy `app_config.example.json` -> `app_config.json`
   - fill WordPress values
3. Run:
   - `flutter run`

## Production Security (Important)

Do not ship real WordPress credentials inside a client app for production.

Recommended production architecture:

1. Flutter app calls your backend API
2. Backend calls WordPress API
3. Backend injects WordPress credentials from server environment variables

Minimum backend controls:

- CORS allowlist
- Input validation
- Rate limiting
- Caching
- Monitoring/logging

If credentials were ever exposed, rotate `WP_APP_PASS` immediately.

## Optional Build-Time Overrides

You can pass values with `--dart-define`:

- `WP_DOMAIN`
- `WP_USER`
- `WP_APP_PASS`
- `ONESIGNAL_APP_ID`
- `ADMOB_ANDROID_APP_ID`
- `ADMOB_IOS_APP_ID`

Example:

```bash
flutter run \
  --dart-define=WP_DOMAIN=https://dashboard.your-site.com \
  --dart-define=WP_USER=your_wp_username \
  --dart-define=WP_APP_PASS=xxxx
```

## Integration Hook Points

- OneSignal: `lib/src/services/notification_service.dart`
- AdMob: `lib/src/services/ad_service.dart`
- Dynamic deep links: `lib/src/services/deep_link_service.dart`

## License

This project is open-source under the **GNU General Public License v3.0**.  
See [LICENSE](LICENSE) for the full license text.
