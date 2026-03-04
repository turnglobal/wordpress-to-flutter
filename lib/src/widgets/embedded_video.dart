import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EmbeddedVideo extends StatefulWidget {
  const EmbeddedVideo({super.key, required this.url});

  final String url;

  @override
  State<EmbeddedVideo> createState() => _EmbeddedVideoState();
}

class _EmbeddedVideoState extends State<EmbeddedVideo> {
  static const _allowedEmbedHosts = <String>{
    'youtube.com',
    'youtu.be',
    'vimeo.com',
    'facebook.com',
    'fb.watch',
    'x.com',
    'twitter.com',
    'platform.twitter.com',
  };

  VideoPlayerController? _videoController;
  WebViewController? _webController;
  bool _blockedEmbed = false;

  bool get _isDirectVideo {
    final lower = widget.url.toLowerCase();
    return lower.endsWith('.mp4') || lower.contains('.m3u8');
  }

  @override
  void initState() {
    super.initState();
    if (_isDirectVideo) {
      final uri = Uri.tryParse(widget.url);
      if (uri == null || !_isSafeVideoUri(uri)) {
        _blockedEmbed = true;
        return;
      }

      _videoController = VideoPlayerController.networkUrl(uri)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
          }
        });
    } else {
      final embedUri = Uri.tryParse(widget.url);
      if (embedUri == null || !_isAllowedEmbedUri(embedUri)) {
        _blockedEmbed = true;
        return;
      }

      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              final uri = Uri.tryParse(request.url);
              if (uri == null || !_isAllowedEmbedUri(uri)) {
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(embedUri);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_blockedEmbed) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'This embed source is blocked for security.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_isDirectVideo) {
      final controller = _videoController;
      if (controller == null || !controller.value.isInitialized) {
        return const SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(controller),
            IconButton(
              onPressed: () {
                setState(() {
                  if (controller.value.isPlaying) {
                    controller.pause();
                  } else {
                    controller.play();
                  }
                });
              },
              icon: Icon(
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
          ],
        ),
      );
    }

    final webController = _webController;
    if (webController == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: WebViewWidget(controller: webController),
      ),
    );
  }

  bool _isAllowedEmbedUri(Uri uri) {
    if (uri.scheme != 'https') {
      return false;
    }

    final host = uri.host.toLowerCase();
    for (final allowed in _allowedEmbedHosts) {
      final normalized = allowed.toLowerCase();
      if (host == normalized || host.endsWith('.$normalized')) {
        return true;
      }
    }
    return false;
  }

  bool _isSafeVideoUri(Uri uri) {
    return uri.scheme == 'https' || uri.scheme == 'http';
  }
}
