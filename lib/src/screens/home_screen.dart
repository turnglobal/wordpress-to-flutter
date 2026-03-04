import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../viewmodels/home_view_model.dart';
import '../widgets/post_card.dart';
import '../widgets/premium_background.dart';
import '../widgets/responsive_frame.dart';
import '../widgets/section_header.dart';
import '../widgets/state_message.dart';
import 'post_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadInitial();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    if (_scrollController.position.extentAfter < 420) {
      context.read<HomeViewModel>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    final content = RefreshIndicator(
      onRefresh: vm.loadInitial,
      child: PremiumBackground(
        child: _HomeBody(
          vm: vm,
          scrollController: _scrollController,
          onOpenPost: (post) => _openPost(context, post),
        ),
      ),
    );

    if (!widget.showScaffold) {
      return content;
    }

    return Scaffold(body: content);
  }

  void _openPost(BuildContext context, WpPost post) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)));
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.vm,
    required this.scrollController,
    required this.onOpenPost,
  });

  final HomeViewModel vm;
  final ScrollController scrollController;
  final ValueChanged<WpPost> onOpenPost;

  @override
  Widget build(BuildContext context) {
    if (vm.loading && vm.latest.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (vm.error != null && vm.latest.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.68,
            child: StateMessage(
              icon: Icons.cloud_off_rounded,
              title: 'Unable to load feed',
              message: vm.error!,
              actionLabel: 'Try again',
              onAction: vm.loadInitial,
            ),
          ),
        ],
      );
    }

    final isFiltering = vm.selectedCategoryId != null;
    final featuredPosts = isFiltering
        ? const <WpPost>[]
        : vm.featured.take(3).toList(growable: false);
    final categoryNameById = {
      for (final category in vm.categories) category.id: category.name,
    };
    final recentPosts = vm.selectedCategoryId == null
        ? vm.latest.skip(featuredPosts.length).toList(growable: false)
        : vm.latest;
    String? selectedCategoryName;
    for (final category in vm.categories) {
      if (category.id == vm.selectedCategoryId) {
        selectedCategoryName = category.name;
        break;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final latestColumns = width >= 1100
            ? 3
            : width >= 760
            ? 2
            : 1;

        return ListView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 10),
          children: [
            ResponsiveFrame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (featuredPosts.isNotEmpty) ...[
                    const SectionHeader(
                      title: 'Featured',
                      subtitle: 'Top stories',
                    ),
                    _FeaturedSpotifyCarousel(
                      posts: featuredPosts,
                      categoryNameById: categoryNameById,
                      onOpenPost: onOpenPost,
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (vm.categories.isNotEmpty) ...[
                    const SectionHeader(
                      title: 'Categories',
                      subtitle: 'Filter stories by topic',
                    ),
                    _CategoriesStrip(vm: vm),
                    const SizedBox(height: 10),
                  ],
                  SectionHeader(
                    title: vm.selectedCategoryId == null
                        ? 'Recent Posts'
                        : selectedCategoryName ?? 'Filtered Posts',
                    subtitle: vm.selectedCategoryId == null
                        ? 'Fresh updates from WordPress'
                        : 'Latest in selected category',
                    trailing: _HeaderPill(
                      icon: Icons.auto_awesome_rounded,
                      label: '${recentPosts.length} posts',
                    ),
                  ),
                  if (recentPosts.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: StateMessage(
                          icon: Icons.article_outlined,
                          title: 'No posts found',
                          message:
                              'Try another category or refresh to load content.',
                        ),
                      ),
                    )
                  else
                    _PostsGrid(
                      posts: recentPosts,
                      columns: latestColumns,
                      onOpenPost: onOpenPost,
                    ),
                  if (vm.loadingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (!vm.hasMore && vm.latest.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Text(
                          'You reached the end',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeaturedSpotifyCarousel extends StatefulWidget {
  const _FeaturedSpotifyCarousel({
    required this.posts,
    required this.categoryNameById,
    required this.onOpenPost,
  });

  final List<WpPost> posts;
  final Map<int, String> categoryNameById;
  final ValueChanged<WpPost> onOpenPost;

  @override
  State<_FeaturedSpotifyCarousel> createState() =>
      _FeaturedSpotifyCarouselState();
}

class _FeaturedSpotifyCarouselState extends State<_FeaturedSpotifyCarousel> {
  late final PageController _controller;
  Timer? _autoTransitionTimer;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88)
      ..addListener(() {
        final page = _controller.page?.round() ?? 0;
        if (page != _activeIndex && mounted) {
          setState(() => _activeIndex = page);
        }
      });
    _setupAutoTransitions();
  }

  @override
  void didUpdateWidget(covariant _FeaturedSpotifyCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.posts.length != widget.posts.length) {
      _setupAutoTransitions();
    }
  }

  @override
  void dispose() {
    _autoTransitionTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _setupAutoTransitions() {
    _autoTransitionTimer?.cancel();
    if (widget.posts.length < 2) {
      return;
    }

    _autoTransitionTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) {
        return;
      }
      final nextIndex = (_activeIndex + 1) % widget.posts.length;
      _controller.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          height: 230,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.posts.length,
            itemBuilder: (context, index) {
              final post = widget.posts[index];
              final primaryCategoryId = post.categoryIds.isNotEmpty
                  ? post.categoryIds.first
                  : null;
              final categoryLabel = primaryCategoryId != null
                  ? widget.categoryNameById[primaryCategoryId]
                  : null;
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final page = _controller.hasClients
                      ? (_controller.page ?? _controller.initialPage.toDouble())
                      : _controller.initialPage.toDouble();
                  final distance = (page - index).abs();
                  final scale = (1 - (distance * 0.08)).clamp(0.9, 1.0);
                  final opacity = (1 - (distance * 0.18)).clamp(0.7, 1.0);
                  return Transform.scale(
                    scale: scale,
                    child: Opacity(opacity: opacity, child: child),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => widget.onOpenPost(post),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (post.thumbnailUrl != null &&
                              post.thumbnailUrl!.isNotEmpty)
                            Image.network(
                              post.thumbnailUrl!,
                              fit: BoxFit.cover,
                              cacheWidth:
                                  (900 * MediaQuery.devicePixelRatioOf(context))
                                      .round(),
                              filterQuality: FilterQuality.low,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: const Color(0xFF181818)),
                            )
                          else
                            Container(color: const Color(0xFF181818)),
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0x22000000), Color(0xBB000000)],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 14,
                            left: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1DB954),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                categoryLabel ?? 'TOP STORY',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 14,
                            right: 14,
                            bottom: 14,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        post.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        post.excerpt,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1DB954),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.posts.length, (index) {
            final isActive = _activeIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _CategoriesStrip extends StatelessWidget {
  const _CategoriesStrip({required this.vm});

  final HomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 8, right: 12),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All'),
              selected: vm.selectedCategoryId == null,
              onSelected: (_) => vm.filterByCategory(null),
            ),
          ),
          ...vm.categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category.name),
                selected: vm.selectedCategoryId == category.id,
                onSelected: (_) => vm.filterByCategory(category.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostsGrid extends StatelessWidget {
  const _PostsGrid({
    required this.posts,
    required this.columns,
    required this.onOpenPost,
  });

  final List<WpPost> posts;
  final int columns;
  final ValueChanged<WpPost> onOpenPost;

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      return Column(
        children: [
          for (var i = 0; i < posts.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            PostCard(
              post: posts[i],
              horizontal: false,
              onTap: () => onOpenPost(posts[i]),
            ),
          ],
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      itemCount: posts.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: columns == 2 ? 0.8 : 0.78,
      ),
      itemBuilder: (context, index) {
        final post = posts[index];
        return PostCard(
          post: post,
          horizontal: false,
          onTap: () => onOpenPost(post),
        );
      },
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurface),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
