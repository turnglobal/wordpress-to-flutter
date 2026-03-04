import 'package:flutter/foundation.dart';

import '../models/category.dart';
import '../models/post.dart';
import '../repositories/post_repository.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._repo);

  final PostRepository _repo;

  List<WpPost> featured = const [];
  List<WpPost> latest = const [];
  List<WpCategory> categories = const [];

  bool loading = false;
  bool loadingMore = false;
  bool hasMore = true;
  int page = 1;

  int? selectedCategoryId;
  String? error;

  Future<void> loadInitial() async {
    loading = true;
    error = null;
    hasMore = true;
    page = 1;
    notifyListeners();

    try {
      final futures = await Future.wait([
        _repo.latest(page: 1),
        _repo.categories(),
      ]);

      latest = futures[0] as List<WpPost>;
      featured = latest.take(3).toList(growable: false);
      categories = futures[1] as List<WpCategory>;
      hasMore = latest.isNotEmpty;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (loading || loadingMore || !hasMore) {
      return;
    }

    loadingMore = true;
    notifyListeners();

    try {
      final nextPage = page + 1;
      final nextItems = selectedCategoryId == null
          ? await _repo.latest(page: nextPage)
          : await _repo.byCategory(selectedCategoryId!, page: nextPage);

      if (nextItems.isEmpty) {
        hasMore = false;
      } else {
        page = nextPage;
        latest = [...latest, ...nextItems];
      }
    } catch (_) {
      hasMore = false;
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> filterByCategory(int? categoryId) async {
    selectedCategoryId = categoryId;
    loading = true;
    page = 1;
    hasMore = true;
    notifyListeners();

    try {
      latest = categoryId == null
          ? await _repo.latest(page: 1)
          : await _repo.byCategory(categoryId, page: 1);
      if (categoryId == null) {
        featured = latest.take(3).toList(growable: false);
      }
      hasMore = latest.isNotEmpty;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
