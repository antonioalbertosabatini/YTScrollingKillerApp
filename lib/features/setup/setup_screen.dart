import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../player/player_screen.dart';
import '../../core/short_url_parser.dart';

/// Local-test setup: enable platform intercept and open a short manually.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _urlController = TextEditingController();
  String? _parseError;

  static const _a11yChannel = MethodChannel(
    'com.ytscrollingkiller.ytscrolling_killer/accessibility',
  );

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _openFromInput() {
    final raw = _urlController.text.trim();
    final id = ShortUrlParser.extractVideoId(raw);
    if (id == null) {
      setState(() => _parseError = 'Could not find a YouTube video id.');
      return;
    }
    setState(() => _parseError = null);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerScreen(videoId: id),
      ),
    );
  }

  Future<void> _openAccessibilitySettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _a11yChannel.invokeMethod<void>('openAccessibilitySettings');
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open settings: ${e.message}')),
      );
    }
  }

  Future<void> _openSafariExtensionHelp() async {
    final uri = Uri.parse('App-prefs:root=SAFARI');
    // Best-effort; Simulator may ignore. Also show in-app instructions.
    try {
      await launchUrl(uri);
    } catch (_) {
      // Ignore — instructions below are the source of truth.
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
            'Stop Shorts scrolling',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'When you open a YouTube Short in a supported browser, this app '
            'takes over and plays only that one video. Use YouTube Home to leave.',
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
              '2. Enable “YTScrollingKiller Shorts Intercept”.\n'
              '3. Open a Short in Chrome (or another supported browser).\n'
              '4. The app should open and play that single Short.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openAccessibilitySettings,
              icon: const Icon(Icons.accessibility_new),
              label: const Text('Open Accessibility settings'),
            ),
            const SizedBox(height: 24),
          ],
          if (isIos) ...[
            Text(
              'iOS setup (Safari)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Install the app on a device/simulator with the Safari Web Extension.\n'
              '2. Open Settings → Apps → Safari → Extensions.\n'
              '3. Enable “YTScrollingKiller” and allow youtube.com.\n'
              '4. Open a Short in Safari — the extension redirects to this app.\n\n'
              'Note: Chrome on iOS does not load Safari extensions.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openSafariExtensionHelp,
              icon: const Icon(Icons.settings),
              label: const Text('Try opening Safari settings'),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            'Test a Short URL',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'Shorts URL or video id',
              hintText: 'https://www.youtube.com/shorts/...',
              errorText: _parseError,
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _openFromInput(),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _openFromInput,
            child: const Text('Open single Short'),
          ),
          const SizedBox(height: 12),
          Text(
            'Deep link format: ytsk://short/{videoId}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
