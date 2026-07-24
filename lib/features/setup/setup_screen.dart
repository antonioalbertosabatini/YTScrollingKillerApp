import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Local-test setup: enable the Android Accessibility guard.
class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  static const _a11yChannel = MethodChannel(
    'com.ytscrollingkiller.ytscrolling_killer/accessibility',
  );

  Future<void> _openAccessibilitySettings(BuildContext context) async {
    if (!Platform.isAndroid) return;
    try {
      await _a11yChannel.invokeMethod<void>('openAccessibilitySettings');
    } on PlatformException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open settings: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final isIos = !kIsWeb && Platform.isIOS;

    return Scaffold(
      appBar: AppBar(
        title: const Text('YTScrollingKiller'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'One Short, then stop',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Watch a YouTube Short normally in your browser. '
            'If you try to scroll to another Short (swipe, related, or autoplay), '
            'a blocking popup appears and you must close the tab.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (isAndroid) ...[
            Text(
              'Android setup',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Tap the button below to open Accessibility settings.\n'
              '2. Enable “YTScrollingKiller Shorts Guard”.\n'
              '3. Open a Short in Chrome (or another supported browser).\n'
              '4. Watch that Short as usual — nothing else happens.\n'
              '5. If you scroll to another Short, the block popup appears.\n'
              '6. Tap “Close tab” (only action available).',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _openAccessibilitySettings(context),
              icon: const Icon(Icons.accessibility_new),
              label: const Text('Open Accessibility settings'),
            ),
            const SizedBox(height: 24),
          ],
          if (isIos) ...[
            Text(
              'iOS',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Browser scroll-blocking is implemented for Android first. '
              'iOS Safari support will follow in a later update.',
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'How it works',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'The Accessibility service watches the browser URL. '
            'Opening a Short is silent. Changing to a different Short id '
            'triggers the overlay. Playback stays in the browser — this app '
            'does not open the video.',
          ),
        ],
      ),
    );
  }
}
