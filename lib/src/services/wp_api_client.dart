import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/category.dart';
import '../models/comment.dart';
import '../models/post.dart';
import 'post_cache.dart';

class WpApiClient {
  WpApiClient({http.Client? httpClient, PostCache? cache})
    : _http = httpClient ?? http.Client(),
      _cache = cache ?? PostCache();

  static const _baseUrlKey = 'wp_base_url';
  static const _usernameKey = 'wp_username';
  static const _appPasswordKey = 'wp_app_password';
  static const _offlineModeKey = 'offline_mode_enabled';
  static const _secureStorage = FlutterSecureStorage();

  final http.Client _http;
  final PostCache _cache;

  Future<void> saveConnection({
    required String baseUrl,
    required String username,
    required String appPassword,
  }) async {
    await _writeSecure(_baseUrlKey, _sanitizeBaseUrl(baseUrl));
    await _writeSecure(_usernameKey, username.trim());
    await _writeSecure(_appPasswordKey, _normalizeAppPassword(appPassword));
  }

  Future<Map<String, String>> getConnection() async {
    String storedBaseUrl = '';
    String storedUsername = '';
    String storedPassword = '';

    try {
      storedBaseUrl = await _secureStorage.read(key: _baseUrlKey) ?? '';
      storedUsername = await _secureStorage.read(key: _usernameKey) ?? '';
      storedPassword = await _secureStorage.read(key: _appPasswordKey) ?? '';
    } catch (_) {
      // Continue with fallback values when secure storage is unavailable.
    }

    // One-time migration from legacy SharedPreferences credential storage.
    if (storedBaseUrl.isEmpty ||
        storedUsername.isEmpty ||
        storedPassword.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final legacyBaseUrl = prefs.getString(_baseUrlKey) ?? '';
      final legacyUsername = prefs.getString(_usernameKey) ?? '';
      final legacyPassword = prefs.getString(_appPasswordKey) ?? '';

      if (storedBaseUrl.isEmpty && legacyBaseUrl.isNotEmpty) {
        storedBaseUrl = _sanitizeBaseUrl(legacyBaseUrl);
        if (await _writeSecure(_baseUrlKey, storedBaseUrl)) {
          await prefs.remove(_baseUrlKey);
        }
      }
      if (storedUsername.isEmpty && legacyUsername.isNotEmpty) {
        storedUsername = legacyUsername.trim();
        if (await _writeSecure(_usernameKey, storedUsername)) {
          await prefs.remove(_usernameKey);
        }
      }
      if (storedPassword.isEmpty && legacyPassword.isNotEmpty) {
        storedPassword = _normalizeAppPassword(legacyPassword);
        if (await _writeSecure(_appPasswordKey, storedPassword)) {
          await prefs.remove(_appPasswordKey);
        }
      }
    }

    return {
      'baseUrl': _sanitizeBaseUrl(
        storedBaseUrl.isNotEmpty ? storedBaseUrl : AppConfig.wpDomain,
      ),
      'username': storedUsername.isNotEmpty ? storedUsername : AppConfig.wpUser,
      'appPassword': storedPassword.isNotEmpty
          ? storedPassword
          : AppConfig.wpAppPass,
    };
  }

  Future<bool> isOfflineModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_offlineModeKey) ?? false;
  }

  Future<void> setOfflineModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineModeKey, enabled);
  }

  Future<void> clearOfflineCache() => _cache.clearAll();

  Future<List<WpPost>> fetchLatestPosts({
    required int page,
    int perPage = 10,
  }) async {
    final uri = await _buildUri(
      '/wp-json/wp/v2/posts',
      query: {
        'page': '$page',
        'per_page': '$perPage',
        '_embed': '1',
        'orderby': 'date',
        'order': 'desc',
      },
    );
    return _fetchPosts(uri, cacheKey: 'latest_$page');
  }

  Future<List<WpPost>> fetchFeaturedPosts({int perPage = 5}) async {
    final featuredUri = await _buildUri(
      '/wp-json/wp/v2/posts',
      query: {'sticky': 'true', 'per_page': '$perPage', '_embed': '1'},
    );
    final featured = await _fetchPosts(featuredUri, cacheKey: 'featured');
    if (featured.isNotEmpty) {
      return featured;
    }

    final fallbackUri = await _buildUri(
      '/wp-json/wp/v2/posts',
      query: {'per_page': '$perPage', '_embed': '1'},
    );
    return _fetchPosts(fallbackUri, cacheKey: 'featured_fallback');
  }

  Future<List<WpCategory>> fetchCategories({int perPage = 20}) async {
    final uri = await _buildUri(
      '/wp-json/wp/v2/categories',
      query: {'per_page': '$perPage', 'orderby': 'count', 'order': 'desc'},
    );

    final response = await _get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load categories (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => WpCategory.fromJson(item as Map<String, dynamic>))
        .where((item) => item.count > 0)
        .toList(growable: false);
  }

  Future<List<WpPost>> fetchPostsByCategory(
    int categoryId, {
    int page = 1,
    int perPage = 10,
  }) async {
    final uri = await _buildUri(
      '/wp-json/wp/v2/posts',
      query: {
        'categories': '$categoryId',
        'page': '$page',
        'per_page': '$perPage',
        '_embed': '1',
      },
    );
    return _fetchPosts(uri, cacheKey: 'cat_${categoryId}_$page');
  }

  Future<List<WpPost>> searchPosts(
    String query, {
    int page = 1,
    int perPage = 10,
  }) async {
    final uri = await _buildUri(
      '/wp-json/wp/v2/posts',
      query: {
        'search': query,
        'page': '$page',
        'per_page': '$perPage',
        '_embed': '1',
      },
    );
    return _fetchPosts(uri, cacheKey: 'search_${query}_$page');
  }

  Future<List<WpComment>> fetchComments(int postId, {int perPage = 20}) async {
    final uri = await _buildUri(
      '/wp-json/wp/v2/comments',
      query: {
        'post': '$postId',
        'per_page': '$perPage',
        'orderby': 'date',
        'order': 'desc',
      },
    );

    final response = await _get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load comments (${response.statusCode})');
    }

    final json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((item) => WpComment.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> submitComment({
    required int postId,
    required String content,
    required String authorName,
    required String authorEmail,
  }) async {
    final uri = await _buildUri('/wp-json/wp/v2/comments');
    final headers = await _headers();
    final requestHeaders = {...headers, 'Content-Type': 'application/json'};

    final payload = jsonEncode({
      'post': postId,
      'content': content.trim(),
      'author_name': authorName.trim(),
      'author_email': authorEmail.trim(),
    });

    http.Response response;
    try {
      response = await _http.post(uri, headers: requestHeaders, body: payload);
    } on ClientException {
      response = await _http.post(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: payload,
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    String message = 'Failed to submit comment (${response.statusCode})';
    try {
      final parsed = jsonDecode(response.body) as Map<String, dynamic>;
      final apiMessage = parsed['message'] as String?;
      if (apiMessage != null && apiMessage.trim().isNotEmpty) {
        message = apiMessage.trim();
      }
    } catch (_) {
      // Keep fallback message.
    }
    throw Exception(message);
  }

  Future<List<WpPost>> fetchRelatedPosts(WpPost post, {int perPage = 6}) async {
    if (post.categoryIds.isEmpty) {
      return const [];
    }

    final primaryCategoryId = post.categoryIds.first;
    final uri = await _buildUri(
      '/wp-json/wp/v2/posts',
      query: {
        'categories': primaryCategoryId.toString(),
        'exclude': post.id.toString(),
        'per_page': '$perPage',
        'orderby': 'date',
        'order': 'desc',
        '_embed': '1',
      },
    );
    final related = await _fetchPosts(
      uri,
      cacheKey: 'related_${post.id}_$primaryCategoryId',
    );
    related.sort((a, b) => b.date.compareTo(a.date));
    return related;
  }

  Future<List<WpPost>> _fetchPosts(Uri uri, {required String cacheKey}) async {
    try {
      final response = await _get(uri);
      if (response.statusCode != 200) {
        throw Exception('Failed to load posts (${response.statusCode})');
      }

      final json = jsonDecode(response.body) as List<dynamic>;
      await _cache.write(cacheKey, json);

      return json
          .map((item) => WpPost.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      final maxAge = await _cacheAgeForCurrentMode();
      final cached = await _cache.read(cacheKey, maxAge: maxAge);
      if (cached == null) {
        rethrow;
      }
      return cached
          .map((item) => WpPost.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    }
  }

  Future<Duration> _cacheAgeForCurrentMode() async {
    final isOfflineMode = await isOfflineModeEnabled();
    return isOfflineMode
        ? const Duration(days: 365)
        : const Duration(minutes: 10);
  }

  Future<http.Response> _get(Uri uri) async {
    final headers = await _headers();
    final hasAuth = headers.containsKey('Authorization');

    try {
      return await _http.get(uri, headers: headers);
    } on ClientException catch (error) {
      if (hasAuth) {
        try {
          return await _http.get(
            uri,
            headers: const {'Accept': 'application/json'},
          );
        } on ClientException catch (fallbackError) {
          _throwFriendlyNetworkException(fallbackError);
        }
      }
      _throwFriendlyNetworkException(error);
    }
  }

  Never _throwFriendlyNetworkException(ClientException error) {
    final message = error.message.toLowerCase();
    if (kIsWeb && message.contains('failed to fetch')) {
      throw Exception(
        'Unable to reach WordPress API from browser. Check CORS and network settings.',
      );
    }
    throw Exception('Unable to connect to WordPress API.');
  }

  Future<Map<String, String>> _headers() async {
    final connection = await getConnection();
    final username = connection['username'] ?? '';
    final appPassword = _normalizeAppPassword(connection['appPassword'] ?? '');

    final hasAuth = username.isNotEmpty && appPassword.isNotEmpty;
    if (!hasAuth) {
      return const {'Accept': 'application/json'};
    }

    final encoded = base64Encode(utf8.encode('$username:$appPassword'));
    return {'Accept': 'application/json', 'Authorization': 'Basic $encoded'};
  }

  Future<Uri> _buildUri(String path, {Map<String, String>? query}) async {
    final connection = await getConnection();
    final baseUrl = connection['baseUrl'] ?? '';
    if (baseUrl.isEmpty) {
      throw Exception('WordPress base URL is not configured');
    }
    return Uri.parse('$baseUrl$path').replace(queryParameters: query);
  }

  String _sanitizeBaseUrl(String value) {
    var url = value.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  String _normalizeAppPassword(String value) {
    return value.trim().replaceAll(' ', '');
  }

  Future<bool> _writeSecure(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      return true;
    } catch (_) {
      return false;
    }
  }
}
