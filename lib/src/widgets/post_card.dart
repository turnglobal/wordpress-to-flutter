import 'package:flutter/material.dart';

import '../models/post.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.compact = false,
    this.horizontal = true,
  });

  final WpPost post;
  final VoidCallback onTap;
  final bool compact;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final thumbHeight = compact ? 104.0 : 138.0;
    final thumbWidth = compact ? 126.0 : 168.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: horizontal
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MediaThumb(
                    url: post.thumbnailUrl,
                    isVideo: post.thumbnailIsVideo,
                    width: thumbWidth,
                    height: thumbHeight,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: _CardBody(post: post, compact: compact),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MediaThumb(
                    url: post.thumbnailUrl,
                    isVideo: post.thumbnailIsVideo,
                    width: double.infinity,
                    height: compact ? 144 : 198,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: _CardBody(post: post, compact: compact),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.post, required this.compact});

  final WpPost post;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryCategory = post.categoryNames.isNotEmpty
        ? post.categoryNames.first
        : 'Uncategorized';
    final footer =
        '${_prettyDate(post.date)} / ${post.authorName} / $primaryCategory';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          post.title,
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.22,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 8),
          Text(
            post.excerpt,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.34),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          footer,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _prettyDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _MediaThumb extends StatelessWidget {
  const _MediaThumb({
    required this.url,
    required this.isVideo,
    required this.width,
    required this.height,
  });

  final String? url;
  final bool isVideo;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dpr = MediaQuery.devicePixelRatioOf(context);
          final logicalWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : width;
          final logicalHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : height;
          final cacheWidth = (logicalWidth * dpr).round().clamp(1, 4096);
          final cacheHeight = (logicalHeight * dpr).round().clamp(1, 4096);

          return Stack(
            fit: StackFit.expand,
            children: [
              if (url != null && url!.isNotEmpty)
                Image.network(
                  url!,
                  fit: BoxFit.cover,
                  cacheWidth: cacheWidth,
                  cacheHeight: cacheHeight,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (context, error, stackTrace) =>
                      _Fallback(theme: theme),
                )
              else
                _Fallback(theme: theme),
              if (isVideo)
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.play_arrow, color: Colors.white),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.colorScheme.surfaceContainerLow,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
