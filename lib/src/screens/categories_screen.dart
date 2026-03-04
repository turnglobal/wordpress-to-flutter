import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/post.dart';
import '../repositories/post_repository.dart';
import '../widgets/post_card.dart';
import '../widgets/premium_background.dart';
import '../widgets/responsive_frame.dart';
import '../widgets/section_header.dart';
import '../widgets/state_message.dart';
import 'post_detail_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _loadingCategories = true;
  bool _loadingPosts = false;
  String? _error;

  List<WpCategory> _categories = const [];
  List<WpPost> _posts = const [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loadingCategories = true;
      _error = null;
    });

    try {
      final repo = context.read<PostRepository>();
      final categories = await repo.categories();
      if (!mounted) {
        return;
      }

      setState(() {
        _categories = categories;
        _selectedCategoryId = null;
      });

      await _loadPosts(null);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingCategories = false);
      }
    }
  }

  Future<void> _loadPosts(int? categoryId) async {
    setState(() {
      _loadingPosts = true;
      _error = null;
      _selectedCategoryId = categoryId;
    });

    try {
      final repo = context.read<PostRepository>();
      final posts = categoryId == null
          ? await repo.latest(page: 1)
          : await repo.byCategory(categoryId, page: 1);
      if (!mounted) {
        return;
      }
      setState(() => _posts = posts);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingPosts = false);
      }
    }
  }

  Widget _buildBody() {
    if (_loadingCategories) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null && _categories.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 520,
            child: StateMessage(
              icon: Icons.error_outline,
              title: 'Unable to load categories',
              message: _error!,
              actionLabel: 'Try again',
              onAction: _loadInitial,
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 3
            : constraints.maxWidth >= 760
            ? 2
            : 1;

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 10),
          children: [
            ResponsiveFrame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  SectionHeader(
                    title: 'Categories',
                    subtitle: _selectedCategoryId == null
                        ? 'Browse all latest posts'
                        : 'Browse posts by topic',
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 10, right: 12),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('All'),
                            selected: _selectedCategoryId == null,
                            onSelected: (_) => _loadPosts(null),
                          ),
                        ),
                        ..._categories.map(
                          (category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category.name),
                              selected: _selectedCategoryId == category.id,
                              onSelected: (_) => _loadPosts(category.id),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_loadingPosts)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_posts.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: StateMessage(
                          icon: Icons.folder_open_outlined,
                          title: 'No posts in this category',
                          message:
                              'Select another category to continue browsing.',
                        ),
                      ),
                    )
                  else
                    _buildPostsLayout(columns),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPostsLayout(int columns) {
    if (columns == 1) {
      return Column(
        children: [
          for (var i = 0; i < _posts.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            PostCard(
              post: _posts[i],
              horizontal: false,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(post: _posts[i]),
                  ),
                );
              },
            ),
          ],
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      itemCount: _posts.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: columns == 2 ? 0.8 : 0.78,
      ),
      itemBuilder: (context, index) {
        final post = _posts[index];
        return PostCard(
          post: post,
          horizontal: false,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = PremiumBackground(child: _buildBody());
    if (!widget.showScaffold) {
      return content;
    }
    return Scaffold(body: content);
  }
}
