import 'package:html/parser.dart' as html_parser;

import '../config/app_config.dart';

class WpPost {
  const WpPost({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.link,
    required this.date,
    required this.authorName,
    required this.categoryIds,
    required this.categoryNames,
    required this.thumbnailUrl,
    required this.thumbnailIsVideo,
  });

  final int id;
  final String title;
  final String excerpt;
  final String content;
  final String link;
  final DateTime date;
  final String authorName;
  final List<int> categoryIds;
  final List<String> categoryNames;
  final String? thumbnailUrl;
  final bool thumbnailIsVideo;

  factory WpPost.fromJson(Map<String, dynamic> json) {
    final embedded = json['_embedded'] as Map<String, dynamic>?;
    final mediaList = embedded?['wp:featuredmedia'] as List<dynamic>?;
    final featuredMedia = mediaList != null && mediaList.isNotEmpty
        ? mediaList.first as Map<String, dynamic>
        : null;

    final mediaType = featuredMedia?['media_type'] as String?;
    final sourceUrl = featuredMedia?['source_url'] as String?;
    final authorList = embedded?['author'] as List<dynamic>?;
    final author = authorList != null && authorList.isNotEmpty
        ? authorList.first as Map<String, dynamic>
        : null;
    final authorName = author?['name'] as String? ?? 'Unknown Author';

    final contentHtml =
        (json['content'] as Map<String, dynamic>?)?['rendered'] as String? ??
        '';
    final firstVideoUrl = _extractFirstVideoUrl(contentHtml);
    final categoryNames = _extractCategoryNames(embedded);

    final thumbnailUrl = _normalizeMediaUrl(sourceUrl ?? firstVideoUrl);

    return WpPost(
      id: json['id'] as int? ?? 0,
      title: _stripHtml(
        (json['title'] as Map<String, dynamic>?)?['rendered'] as String? ?? '',
      ),
      excerpt: _stripHtml(
        (json['excerpt'] as Map<String, dynamic>?)?['rendered'] as String? ??
            '',
      ),
      content: contentHtml,
      link: _normalizeMediaUrl(json['link'] as String? ?? '') ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      authorName: authorName,
      categoryIds: ((json['categories'] as List<dynamic>?) ?? const [])
          .map((e) => e as int)
          .toList(growable: false),
      categoryNames: categoryNames,
      thumbnailUrl: thumbnailUrl,
      thumbnailIsVideo: mediaType == 'video' || _isVideoUrl(thumbnailUrl),
    );
  }

  static String _stripHtml(String input) {
    if (input.isEmpty) {
      return '';
    }
    return html_parser.parse(input).documentElement?.text.trim() ?? input;
  }

  static bool _isVideoUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    final normalized = url.toLowerCase();
    return normalized.endsWith('.mp4') ||
        normalized.endsWith('.m3u8') ||
        normalized.contains('youtube.com') ||
        normalized.contains('youtu.be') ||
        normalized.contains('vimeo.com');
  }

  static String? _extractFirstVideoUrl(String html) {
    if (html.isEmpty) {
      return null;
    }

    final document = html_parser.parse(html);

    final iframe = document.querySelector('iframe');
    final iframeSrc = iframe?.attributes['src'];
    if (iframeSrc != null && iframeSrc.isNotEmpty) {
      return iframeSrc;
    }

    final video = document.querySelector('video');
    final videoSrc = video?.attributes['src'];
    if (videoSrc != null && videoSrc.isNotEmpty) {
      return videoSrc;
    }

    final source = video?.querySelector('source');
    final sourceSrc = source?.attributes['src'];
    if (sourceSrc != null && sourceSrc.isNotEmpty) {
      return sourceSrc;
    }

    return null;
  }

  static String? _normalizeMediaUrl(String? input) {
    if (input == null || input.isEmpty) {
      return input;
    }

    final normalizedInput = input.replaceAll('&amp;', '&').trim();
    final wpDomain = AppConfig.wpDomain.trim();
    if (wpDomain.isEmpty) {
      return normalizedInput;
    }

    final wpUri = Uri.tryParse(wpDomain);
    if (wpUri == null) {
      return normalizedInput;
    }

    if (normalizedInput.startsWith('//')) {
      return '${wpUri.scheme}:$normalizedInput';
    }

    final inputUri = Uri.tryParse(normalizedInput);
    if (inputUri == null) {
      return normalizedInput;
    }

    if (!inputUri.hasScheme && normalizedInput.startsWith('/')) {
      return wpUri.resolveUri(inputUri).toString();
    }

    if (!inputUri.hasScheme && inputUri.host.isEmpty) {
      return wpUri.resolve(normalizedInput).toString();
    }

    // Keep absolute media URLs as-is; WordPress/CDN may use a different host.
    return normalizedInput;
  }

  static List<String> _extractCategoryNames(Map<String, dynamic>? embedded) {
    if (embedded == null) {
      return const [];
    }

    final wpTerms = embedded['wp:term'] as List<dynamic>?;
    if (wpTerms == null || wpTerms.isEmpty) {
      return const [];
    }

    final names = <String>{};
    for (final termGroup in wpTerms) {
      final terms = termGroup as List<dynamic>?;
      if (terms == null) {
        continue;
      }
      for (final item in terms) {
        final term = item as Map<String, dynamic>;
        final taxonomy = term['taxonomy'] as String?;
        if (taxonomy == 'category') {
          final name = term['name'] as String?;
          if (name != null && name.trim().isNotEmpty) {
            names.add(name.trim());
          }
        }
      }
    }
    return names.toList(growable: false);
  }
}
