import 'dart:async';

import 'package:flutter/material.dart';

import 'core/deep_links.dart';
import 'features/player/player_screen.dart';
import 'features/setup/setup_screen.dart';

class YtScrollingKillerApp extends StatefulWidget {
  const YtScrollingKillerApp({super.key, this.deepLinkService});

  final DeepLinkService? deepLinkService;

  @override
  State<YtScrollingKillerApp> createState() => _YtScrollingKillerAppState();
}

class _YtScrollingKillerAppState extends State<YtScrollingKillerApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final DeepLinkService _deepLinks;
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    _deepLinks = widget.deepLinkService ?? DeepLinkService();
    unawaited(_deepLinks.start());
    _sub = _deepLinks.videoIdStream.listen(_openPlayer);
  }

  void _openPlayer(String videoId) {
    final nav = _navigatorKey.currentState;
    if (nav == null) return;
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerScreen(videoId: videoId),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel() ?? Future<void>.value());
    unawaited(_deepLinks.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YTScrollingKiller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      navigatorKey: _navigatorKey,
      home: const SetupScreen(),
    );
  }
}
