# wp2fapp

Flutter app foundation for consuming WordPress content through the WP REST API on both Android and iOS.

## Credits

- Fully developed by Chandima Galahitiyawa.
- Funded by Turn.Global for the community.
- Released under the GNU General Public License v3.0 (see `LICENSE`).

## Implemented Foundation

- WordPress API connection with Application Password support
- Latest posts feed with infinite scroll
- Featured posts section
- Categories filter chips
- Post search screen
- Post detail with comments, related posts, embedded media, and share
- Light / dark / system theme switching
- Local caching via `SharedPreferences`
- Integration scaffolding for OneSignal, AdMob, and dynamic deep links

## Root Config File

Edit the root file:

- `/Users/user/StudioProjects/wp2fapp/app_config.json`

Use these global keys:

- `wp_domain`
- `wp_user`
- `wp_app_pass`

Optional integration keys:

- `oneSignalAppId`
- `admobAndroidAppId`
- `admobIosAppId`

You can copy from:

- `/Users/user/StudioProjects/wp2fapp/app_config.example.json`

The app loads this file at startup and uses it globally for API/auth/media URL normalization.

Security note:

- Do not commit real `wp_user` / `wp_app_pass` values.
- Prefer build-time defines for production:
  - `--dart-define=WP_DOMAIN=...`
  - `--dart-define=WP_USER=...`
  - `--dart-define=WP_APP_PASS=...`
- `wp_app_pass` in a client app is still extractable from the built binary. For production-grade security, use a backend proxy/token service instead of direct WordPress application-password auth from client.

## Production API Proxy (Recommended)

To make this app production-safe, keep WordPress credentials on a backend server and let the app call your backend API.

### Why

- Mobile/web client binaries can be reverse-engineered.
- Any credential bundled in app config can be extracted.
- A backend proxy lets you apply rate limits, validation, caching, and abuse controls.

### Architecture

1. Flutter app -> your backend API (`https://api.yourdomain.com`)
2. Backend API -> WordPress REST API (`https://dash.yourdomain.com/wp-json/...`)
3. Backend injects `Authorization: Basic ...` using server environment variables only.

### Required backend env vars

- `WP_BASE_URL`
- `WP_USER`
- `WP_APP_PASS`

Optional:

- `APP_API_KEY` or JWT secret for client auth
- Redis URL for caching

### Endpoint design options

Option A (zero Flutter code changes): Transparent proxy  
Mirror the same WordPress routes under your API domain, for example:

- `GET /wp-json/wp/v2/posts`
- `GET /wp-json/wp/v2/categories`
- `GET /wp-json/wp/v2/comments`
- `POST /wp-json/wp/v2/comments`

Then set `wp_domain` to your API domain in `app_config.json`.

Option B (custom API contract):  
Create app-specific endpoints:

- `GET /posts/latest`
- `GET /posts/featured`
- `GET /posts/category/:id`
- `GET /categories`
- `GET /posts/search?q=...`
- `GET /posts/:id/comments`
- `POST /posts/:id/comments`

This requires updating Flutter data layer route paths.

### Minimum backend security controls

- CORS allowlist (web origin only)
- Request validation and payload size limits
- Rate limiting per IP/device/user
- Short cache for public feed endpoints
- Structured logs and monitoring
- Abuse protection for comments

### Rotation policy

- Rotate WordPress App Password immediately if it was ever committed.
- Revoke old credentials after backend deployment.

## Platform Readiness

### Android

- `INTERNET`, `ACCESS_NETWORK_STATE`, and `AD_ID` permissions are added in `android/app/src/main/AndroidManifest.xml`.

### iOS

- `NSAppTransportSecurity` + `NSAllowsArbitraryLoadsInWebContent` is added in `ios/Runner/Info.plist` for embedded web media.

## Setup

1. Install dependencies:
   - `flutter pub get`
2. Edit `app_config.json` with your WordPress details.
3. Run app on Android or iOS.

## Integration Hook Points

- OneSignal: `/Users/user/StudioProjects/wp2fapp/lib/src/services/notification_service.dart`
- AdMob: `/Users/user/StudioProjects/wp2fapp/lib/src/services/ad_service.dart`
- Dynamic links: `/Users/user/StudioProjects/wp2fapp/lib/src/services/deep_link_service.dart`
