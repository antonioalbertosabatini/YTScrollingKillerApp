import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'short_url_parser.dart';

/// Listens for `ytsk://short/{id}` and YouTube Shorts https links.
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;

  /// Emits video ids extracted from incoming links.
  Stream<String> get videoIdStream => _controller.stream;
  final _controller = StreamController<String>.broadcast();

  Future<void> start() async {
    try {
      final initial = await _appLinks.getInitialLink();
      _handleUri(initial);
    } catch (e, st) {
      debugPrint('DeepLinkService initial link error: $e\n$st');
    }

    _subscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object e, StackTrace st) {
        debugPrint('DeepLinkService stream error: $e\n$st');
      },
    );
  }

  void _handleUri(Uri? uri) {
    if (uri == null) return;
    final id = ShortUrlParser.extractVideoId(uri.toString());
    if (id != null) {
      _controller.add(id);
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
