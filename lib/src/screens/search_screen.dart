import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../repositories/post_repository.dart';
import '../widgets/post_card.dart';
import '../widgets/premium_background.dart';
import '../widgets/responsive_frame.dart';
import '../widgets/state_message.dart';
import 'post_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  List<WpPost> _results = const [];

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = context.read<PostRepository>();
      final items = await repo.search(query);
      if (!mounted) {
        return;
      }
      setState(() => _results = items);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 3
            : constraints.maxWidth >= 760
            ? 2
            : 1;

        return ListView(
          children: [
            ResponsiveFrame(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  SearchBar(
                    controller: _controller,
                    hintText: 'Search by title, tag, or keyword',
                    elevation: const WidgetStatePropertyAll(0),
                    trailing: [
                      IconButton(
                        onPressed: _search,
                        icon: const Icon(Icons.search_rounded),
                      ),
                    ],
                    onSubmitted: (_) => _search(),
                  ),
                  const SizedBox(height: 12),
                  if (_loading) const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  if (_error != null)
                    SizedBox(
                      height: 360,
                      child: StateMessage(
                        icon: Icons.error_outline,
                        title: 'Search failed',
                        message: _error!,
                        actionLabel: 'Retry',
                        onAction: _search,
                      ),
                    )
                  else if (_results.isEmpty)
                    const SizedBox(
                      height: 360,
                      child: StateMessage(
                        icon: Icons.travel_explore_rounded,
                        title: 'Find stories instantly',
                        message:
                            'Search the latest WordPress posts with keywords.',
                      ),
                    )
                  else
                    _buildResultsLayout(columns),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResultsLayout(int columns) {
    if (columns == 1) {
      return Column(
        children: [
          for (var i = 0; i < _results.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            PostCard(
              post: _results[i],
              horizontal: false,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(post: _results[i]),
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
      itemCount: _results.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: columns == 2 ? 0.8 : 0.78,
      ),
      itemBuilder: (context, index) {
        final post = _results[index];
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
