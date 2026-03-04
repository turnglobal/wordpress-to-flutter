# WordPress to Flutter (Android and iOS Support)

A production-focused Flutter starter app that converts any WordPress site into a modern mobile news/content app for Android and iOS.

This project uses the WordPress REST API, Material 3 UI, category-based browsing, search, comments, sharing, related posts, offline cache mode, and reusable integration points for notifications, ads, and deep links.

SEO keywords: WordPress to Flutter, Flutter WordPress app, WordPress REST API mobile app, Android iOS WordPress app template, Flutter news app template.

## App Preview

![WordPress to Flutter app preview](https://i.imgur.com/5QIwXpn.png)

## Why This Template

- One codebase for Android and iOS
- WordPress-connected out of the box
- Premium-style Material 3 responsive UI
- Config-driven setup through a single root config file
- Clear extension points for production integrations

## Implemented Features

- WordPress API authentication using Application Password
- Latest posts feed with infinite scroll
- Featured top 3 posts slider
- Categories list and category-based filtering
- Search posts
- Post detail page with:
  - Cover image/video thumbnail support
  - Embedded video rendering from post content
  - Metadata (date, author, category)
- Share post link
- WordPress comments:
  - Load existing comments
  - Submit new comments
- Related posts from the same category
- Theme modes: System / Light / Dark
- Offline cache mode + clear cached content
- Settings page with app preferences and legal links
- Integration hook points for OneSignal, AdMob, Dynamic Links

## Project Stack

- Flutter + Material 3
- Provider for state management
- `http` for API requests
- `shared_preferences` for settings/cache persistence
- `flutter_secure_storage` for commenter identity fields

## Quick Start

### 1. Prerequisites

- Flutter SDK installed
- Android Studio / Xcode set up for Flutter
- A WordPress site with REST API enabled
- A WordPress user with an Application Password

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure the app

Copy the example file and edit values:

```bash
cp app_config.example.json app_config.json
```

Then update `app_config.json`.

Do not commit real production credentials to source control.

### 4. Run

```bash
flutter run
```

## Configuration (`app_config.json`)

The app reads configuration globally from `app_config.json` in the project root.

### Supported keys

- `app_name`: App display name (title + splash label)
- `wp_domain`: WordPress base URL used for REST API (example: `https://dash.example.com`)
- `wp_user`: WordPress username for Application Password auth
- `wp_app_pass`: WordPress Application Password
- `app_icon_path`: App icon/brand fallback asset path or URL
- `app_logo_path`: Logo path or URL used in branded splash screen
- `oneSignalAppId`: OneSignal App ID (optional)
- `admobAndroidAppId`: AdMob Android App ID (optional)
- `admobIosAppId`: AdMob iOS App ID (optional)

### Example

```json
{
  "app_name": "Web2Flutter",
  "wp_domain": "https://dashboard.your-site.com",
  "wp_user": "your_wp_username",
  "wp_app_pass": "xxxx xxxx xxxx xxxx xxxx xxxx",
  "app_icon_path": "assets/branding/app_icon.png",
  "app_logo_path": "assets/branding/app_logo.png",
  "oneSignalAppId": "your_onesignal_app_id",
  "admobAndroidAppId": "ca-app-pub-xxxxxxxxxxxxxxxx~xxxxxxxxxx",
  "admobIosAppId": "ca-app-pub-xxxxxxxxxxxxxxxx~xxxxxxxxxx"
}
```

## WordPress Requirements

For reliable API access:

1. Ensure REST API is accessible:
   - `https://your-domain.com/wp-json/`
2. Create an Application Password in WordPress user profile
3. Use a user role with permission to read posts/categories and submit comments
4. If media does not load, verify:
   - WordPress/media URLs are publicly accessible
   - No firewall/security plugin is blocking API/media requests
   - Correct protocol/domain (`https://...`) in `wp_domain`

## Run and Build

### Development

```bash
flutter run
```

### Analyze

```bash
flutter analyze
```

### Test

```bash
flutter test
```

### Android APK

```bash
flutter build apk --debug
```

### iOS

```bash
flutter run -d ios
```

## Integration Hook Points

These are intentionally left as clean extension points:

- Notifications (OneSignal): `lib/src/services/notification_service.dart`
- Ads (AdMob): `lib/src/services/ad_service.dart`
- Dynamic links: `lib/src/services/deep_link_service.dart`

Add production SDK setup in these files without changing app-level feature flow.

## Security Notice (Important)

This template supports direct WordPress auth from the app for quick setup and demos.

For real production environments, do not rely on shipping raw WordPress credentials in a client app. They can be extracted from a built binary.

Recommended approach:

1. Mobile app calls your own backend API
2. Backend calls WordPress API using server-side credentials
3. Backend returns only required data to the app

If credentials are exposed, rotate `wp_app_pass` immediately.

## Production API Proxy (Recommended)

Use this architecture for scale and security:

1. Edge/CDN Layer
- WAF, TLS, bot filtering, coarse rate limiting

2. API Gateway Layer
- Single entry domain (`api.yourdomain.com`)
- Auth, quotas, CORS allowlist, request limits

3. Proxy Service Layer
- Stateless API instances
- Strict allowlist of upstream WordPress endpoints
- Input validation and response shaping

4. Caching Layer
- Redis/in-memory cache for hot routes (`latest`, `featured`, `categories`, `search`)
- TTL-based invalidation for freshness

5. Observability & Operations
- Structured logs, metrics, tracing, alerts
- Retries, timeouts, circuit breakers

6. Stable Mobile Contract
- Versioned endpoints like `/v1/posts/latest`, `/v1/posts/search`, `/v1/comments`
- Keep mobile response schema stable regardless of WordPress internals

## Troubleshooting

### Android build fails after major dependency upgrades

If you see Kotlin/plugin errors (for example unresolved classes from `share_plus` or `package_info_plus`), keep these compatible versions:

- `share_plus: ^10.1.4`
- `package_info_plus: ^8.3.1`

Then run:

```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### ADB install error: Broken pipe (32)

```bash
adb kill-server
adb start-server
flutter run
```

### Web build note

This repository is configured for Android and iOS. If you also want Web support, run:

```bash
flutter create .
```

## Project Structure

- `lib/src/config/` app configuration loading
- `lib/src/services/` API, cache, and integration services
- `lib/src/repositories/` data repository layer
- `lib/src/viewmodels/` state/view models
- `lib/src/screens/` screens and app shell
- `lib/src/widgets/` reusable UI components

## Community Credits

- Fully developed by **Chandima Galahitiyawa**
- Funded by **Turn.Global** for the community

## Contributing

Community contributions are welcome.

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Open a pull request with clear test notes

## License

This project is **100% free and open-source** under the **GNU General Public License v3.0 (GPL-3.0)**.

Anyone can:

- Use it for personal or commercial projects
- Modify the source code
- Develop and distribute their own versions

No license fee, royalty, or paid permission is required.

GPL note for redistribution:

- Keep the same GPL-3.0 license
- Keep copyright/license notices
- Provide source code for distributed modified builds

This software is provided without warranty, as defined by GPL-3.0.

See [LICENSE](LICENSE) for the full license text.
