import '../models/category.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../services/wp_api_client.dart';

class PostRepository {
  PostRepository(this._api);

  final WpApiClient _api;

  Future<List<WpPost>> latest({required int page, int perPage = 10}) =>
      _api.fetchLatestPosts(page: page, perPage: perPage);

  Future<List<WpPost>> featured({int perPage = 5}) =>
      _api.fetchFeaturedPosts(perPage: perPage);

  Future<List<WpCategory>> categories() => _api.fetchCategories();

  Future<List<WpPost>> byCategory(
    int categoryId, {
    int page = 1,
    int perPage = 10,
  }) => _api.fetchPostsByCategory(categoryId, page: page, perPage: perPage);

  Future<List<WpPost>> search(String query, {int page = 1, int perPage = 10}) =>
      _api.searchPosts(query, page: page, perPage: perPage);

  Future<List<WpComment>> comments(int postId) => _api.fetchComments(postId);

  Future<void> submitComment({
    required int postId,
    required String content,
    required String authorName,
    required String authorEmail,
  }) => _api.submitComment(
    postId: postId,
    content: content,
    authorName: authorName,
    authorEmail: authorEmail,
  );

  Future<List<WpPost>> related(WpPost post) => _api.fetchRelatedPosts(post);

  Future<void> saveConnection({
    required String baseUrl,
    required String username,
    required String appPassword,
  }) => _api.saveConnection(
    baseUrl: baseUrl,
    username: username,
    appPassword: appPassword,
  );

  Future<Map<String, String>> getConnection() => _api.getConnection();

  Future<bool> isOfflineModeEnabled() => _api.isOfflineModeEnabled();

  Future<void> setOfflineModeEnabled(bool enabled) =>
      _api.setOfflineModeEnabled(enabled);

  Future<void> clearOfflineCache() => _api.clearOfflineCache();
}
