import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../repositories/post_repository.dart';
import '../widgets/embedded_video.dart';
import '../widgets/post_card.dart';
import '../widgets/premium_background.dart';
import '../widgets/responsive_frame.dart';
import '../widgets/section_header.dart';
import '../widgets/state_message.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.post});

  final WpPost post;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  static const _commenterNameKey = 'commenter_name';
  static const _commenterEmailKey = 'commenter_email';
  static const _secureStorage = FlutterSecureStorage();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _commentController = TextEditingController();

  late Future<List<WpComment>> _commentsFuture;
  late List<_ContentBlock> _contentBlocks;
  late String? _embeddedVideo;
  late String _primaryCategory;
  bool _submittingComment = false;

  @override
  void initState() {
    super.initState();
    _hydratePostData();
    _commentsFuture = context.read<PostRepository>().comments(widget.post.id);
    _loadCommenterIdentity();
  }

  @override
  void didUpdateWidget(covariant PostDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _hydratePostData();
      _commentsFuture = context.read<PostRepository>().comments(widget.post.id);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadCommenterIdentity() async {
    String? storedName;
    String? storedEmail;
    try {
      storedName = await _secureStorage.read(key: _commenterNameKey);
      storedEmail = await _secureStorage.read(key: _commenterEmailKey);
    } catch (_) {
      // Ignore storage read failures; app continues without remembered identity.
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _nameController.text = storedName ?? '';
      _emailController.text = storedEmail ?? '';
    });
  }

  Future<void> _refreshComments() async {
    setState(() {
      _commentsFuture = context.read<PostRepository>().comments(widget.post.id);
    });
  }

  Future<void> _submitComment() async {
    if (_submittingComment) {
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final comment = _commentController.text.trim();

    if (name.isEmpty || email.isEmpty || comment.isEmpty) {
      _showSnackBar('Please fill name, email, and comment.');
      return;
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(email)) {
      _showSnackBar('Please enter a valid email address.');
      return;
    }

    setState(() => _submittingComment = true);
    try {
      final repo = context.read<PostRepository>();
      await repo.submitComment(
        postId: widget.post.id,
        content: comment,
        authorName: name,
        authorEmail: email,
      );

      try {
        await _secureStorage.write(key: _commenterNameKey, value: name);
        await _secureStorage.write(key: _commenterEmailKey, value: email);
      } catch (_) {
        // Ignore storage write failures; comment flow should still succeed.
      }

      _commentController.clear();
      await _refreshComments();
      _showSnackBar('Comment submitted. It may appear after moderation.');
    } catch (e) {
      _showSnackBar(_errorText(e));
    } finally {
      if (mounted) {
        setState(() => _submittingComment = false);
      }
    }
  }

  void _hydratePostData() {
    final post = widget.post;
    _embeddedVideo = _extractFirstVideoUrl(post.content);
    _contentBlocks = _extractContentBlocks(post.content);
    _primaryCategory = post.categoryNames.isNotEmpty
        ? post.categoryNames.first
        : 'Uncategorized';
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<PostRepository>();
    final post = widget.post;
    final embeddedVideo = _embeddedVideo;
    final contentBlocks = _contentBlocks;
    final primaryCategory = _primaryCategory;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Share',
            onPressed: () => Share.share(post.link),
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: PremiumBackground(
        child: ListView(
          children: [
            ResponsiveFrame(
              maxWidth: 980,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800, height: 1.2),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _MetaInline(
                            icon: Icons.calendar_month_outlined,
                            label: _formatDate(post.date),
                          ),
                          const _MetaDivider(),
                          _MetaInline(
                            icon: Icons.person_outline,
                            label: post.authorName,
                          ),
                          const _MetaDivider(),
                          _MetaInline(
                            icon: Icons.category_outlined,
                            label: primaryCategory,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (post.thumbnailUrl != null &&
                        post.thumbnailUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          post.thumbnailUrl!,
                          height: 260,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          cacheWidth:
                              (MediaQuery.sizeOf(context).width *
                                      MediaQuery.devicePixelRatioOf(context))
                                  .round(),
                          filterQuality: FilterQuality.low,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    if (embeddedVideo != null) ...[
                      const SizedBox(height: 14),
                      EmbeddedVideo(url: embeddedVideo),
                    ],
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _ArticleContent(blocks: contentBlocks),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const SectionHeader(
                      title: 'Comments',
                      subtitle: 'Community discussion on this post',
                    ),
                    FutureBuilder<List<WpComment>>(
                      future: _commentsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (snapshot.hasError) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: StateMessage(
                                icon: Icons.error_outline,
                                title: 'Comments unavailable',
                                message: 'Unable to load comments right now.',
                                actionLabel: 'Retry',
                                onAction: _refreshComments,
                              ),
                            ),
                          );
                        }

                        final comments = snapshot.data ?? const [];
                        if (comments.isEmpty) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(18),
                              child: StateMessage(
                                icon: Icons.chat_bubble_outline,
                                title: 'No comments yet',
                                message:
                                    'Be the first to react on the original post.',
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: comments
                              .map(
                                (comment) => Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          comment.authorName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _plainTextFromHtml(comment.content),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(height: 1.34),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const SectionHeader(
                      title: 'Add Comment',
                      subtitle: 'Join the discussion',
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                hintText: 'Your name',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'name@example.com',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _commentController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Comment',
                                hintText: 'Write your comment...',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                onPressed: _submittingComment
                                    ? null
                                    : _submitComment,
                                icon: _submittingComment
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded),
                                label: Text(
                                  _submittingComment
                                      ? 'Submitting...'
                                      : 'Submit Comment',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const SectionHeader(
                      title: 'Related Posts',
                      subtitle: 'More posts you may like',
                    ),
                    FutureBuilder<List<WpPost>>(
                      future: repo.related(post),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final related = snapshot.data ?? const [];
                        if (related.isEmpty) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(18),
                              child: StateMessage(
                                icon: Icons.auto_stories_outlined,
                                title: 'No related stories',
                                message:
                                    'Check back later for similar articles.',
                              ),
                            ),
                          );
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 900 ? 2 : 1;
                            if (columns == 1) {
                              return Column(
                                children: [
                                  for (var i = 0; i < related.length; i++) ...[
                                    if (i > 0) const SizedBox(height: 12),
                                    PostCard(
                                      post: related[i],
                                      compact: true,
                                      horizontal: true,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => PostDetailScreen(
                                              post: related[i],
                                            ),
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
                              itemCount: related.length,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.9,
                                  ),
                              itemBuilder: (context, index) {
                                final item = related[index];
                                return PostCard(
                                  post: item,
                                  compact: true,
                                  horizontal: false,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PostDetailScreen(post: item),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _plainTextFromHtml(String value) {
    final raw = html_parser.parse(value).documentElement?.text ?? value;
    return _normalizeWhitespace(raw);
  }

  List<_ContentBlock> _extractContentBlocks(String html) {
    final document = html_parser.parse(html);
    final selected = document.querySelectorAll('h2, h3, h4, p, li, blockquote');
    final blocks = <_ContentBlock>[];

    for (final node in selected) {
      final local = node.localName?.toLowerCase();
      var text = _normalizeWhitespace(node.text);
      if (text.isEmpty) {
        continue;
      }

      if (local == 'li') {
        text = '• $text';
      } else if (local == 'blockquote') {
        text = '"$text"';
      }

      blocks.add(
        _ContentBlock(
          text: text,
          isHeading: local == 'h2' || local == 'h3' || local == 'h4',
        ),
      );
    }

    if (blocks.isEmpty) {
      final fallback = _plainTextFromHtml(html);
      if (fallback.isNotEmpty) {
        blocks.add(_ContentBlock(text: fallback, isHeading: false));
      }
    }

    return blocks;
  }

  String _normalizeWhitespace(String value) {
    return value
        .replaceAll(RegExp(r'[\u00A0\t\r\n]+'), ' ')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String? _extractFirstVideoUrl(String html) {
    final document = html_parser.parse(html);
    final iframeSrc = document.querySelector('iframe')?.attributes['src'];
    if (iframeSrc != null && iframeSrc.isNotEmpty) {
      return iframeSrc;
    }

    final video = document.querySelector('video');
    final directSrc = video?.attributes['src'];
    if (directSrc != null && directSrc.isNotEmpty) {
      return directSrc;
    }

    final sourceSrc = video?.querySelector('source')?.attributes['src'];
    if (sourceSrc != null && sourceSrc.isNotEmpty) {
      return sourceSrc;
    }

    return null;
  }

  String _errorText(Object error) {
    final raw = error.toString();
    const prefix = 'Exception: ';
    if (raw.startsWith(prefix)) {
      return raw.substring(prefix.length);
    }
    return raw;
  }
}

class _MetaInline extends StatelessWidget {
  const _MetaInline({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MetaDivider extends StatelessWidget {
  const _MetaDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        '•',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.outline,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ArticleContent extends StatelessWidget {
  const _ArticleContent({required this.blocks});

  final List<_ContentBlock> blocks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          Text(
            blocks[i].text,
            style: blocks[i].isHeading
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.28,
                  )
                : theme.textTheme.bodyLarge?.copyWith(height: 1.4),
          ),
        ],
      ],
    );
  }
}

class _ContentBlock {
  const _ContentBlock({required this.text, required this.isHeading});

  final String text;
  final bool isHeading;
}
