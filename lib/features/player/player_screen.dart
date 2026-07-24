import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _youtubeHome = 'https://www.youtube.com/';

/// Plays a single YouTube video via IFrame embed (no Shorts feed).
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.videoId});

  final String videoId;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final WebViewController _controller;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _loading = false;
                _error = 'Unable to load this video.';
              });
            }
          },
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.contains('/shorts/') &&
                !url.contains('youtube-nocookie.com')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    _loadEmbed();
  }

  Future<void> _loadEmbed() async {
    final html = _embedHtml(widget.videoId);
    final uri = Uri.dataFromString(
      html,
      mimeType: 'text/html',
      encoding: utf8,
    );
    await _controller.loadRequest(uri);
  }

  String _embedHtml(String videoId) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
  <style>
    html, body { margin:0; padding:0; width:100%; height:100%; background:#000; overflow:hidden; touch-action:none; }
    #player { width:100%; height:100%; }
  </style>
</head>
<body>
  <div id="player"></div>
  <script>
    var tag = document.createElement('script');
    tag.src = 'https://www.youtube.com/iframe_api';
    document.head.appendChild(tag);
    function onYouTubeIframeAPIReady() {
      new YT.Player('player', {
        videoId: '$videoId',
        host: 'https://www.youtube-nocookie.com',
        playerVars: {
          autoplay: 1,
          playsinline: 1,
          rel: 0,
          modestbranding: 1,
          fs: 1,
          controls: 1,
          iv_load_policy: 3
        },
        events: {
          onReady: function (e) { e.target.playVideo(); }
        }
      });
    }
    document.addEventListener('touchmove', function (e) { e.preventDefault(); }, { passive: false });
    document.addEventListener('wheel', function (e) { e.preventDefault(); }, { passive: false });
  </script>
</body>
</html>
''';
  }

  Future<void> _goToYoutubeHome() async {
    final uri = Uri.parse(_youtubeHome);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Single Short'),
        actions: [
          TextButton.icon(
            onPressed: _goToYoutubeHome,
            icon: const Icon(Icons.home_outlined, color: Colors.white),
            label: const Text(
              'YouTube Home',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_error == null) WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _goToYoutubeHome,
                      child: const Text('Go to YouTube Home'),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _goToYoutubeHome,
                icon: const Icon(Icons.home),
                label: const Text('Go to YouTube Home'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
