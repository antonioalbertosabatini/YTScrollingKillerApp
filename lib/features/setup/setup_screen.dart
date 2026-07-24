import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app.dart';

/// Local-test setup: enable the Android Accessibility guard.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  static const _a11yChannel = MethodChannel(
    'com.ytscrollingkiller.ytscrolling_killer/accessibility',
  );

  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _cutWidth;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _fade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _cutWidth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.35, 0.9, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _entrance.value = 1;
    } else if (!_entrance.isAnimating && _entrance.value == 0) {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

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
    final textTheme = Theme.of(context).textTheme;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: ListView(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 28 + bottom),
              children: [
                Text(
                  'YTScrollingKiller',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedBuilder(
                  animation: _cutWidth,
                  builder: (context, _) {
                    final maxWidth = MediaQuery.sizeOf(context).width * 0.28;
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: maxWidth * _cutWidth.value.clamp(0.0, 1.0),
                        height: 2,
                        decoration: BoxDecoration(
                          color: SessionCutColors.accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                Text(
                  'One Short, then stop',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Watch one YouTube Short in your browser. '
                  'If you scroll to another (swipe, related, or autoplay), '
                  'playback pauses and a block appears — then you close the tab.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: SessionCutColors.muted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 32),
                if (isAndroid) ...[
                  FilledButton.icon(
                    onPressed: () => _openAccessibilitySettings(context),
                    icon: const Icon(Icons.accessibility_new_rounded),
                    label: const Text('Open Accessibility settings'),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Android setup',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SetupStep(
                    number: '1',
                    text: 'Open Accessibility settings and enable '
                        '“YTScrollingKiller Shorts Guard”.',
                  ),
                  const _SetupStep(
                    number: '2',
                    text: 'Open a Short in Chrome (or another supported browser).',
                  ),
                  const _SetupStep(
                    number: '3',
                    text: 'Watch that Short as usual — nothing else happens.',
                  ),
                  const _SetupStep(
                    number: '4',
                    text: 'Scroll to another Short — playback pauses and '
                        'the block appears.',
                  ),
                  const _SetupStep(
                    number: '5',
                    text: 'Tap “Close tab” — the only action available.',
                    isLast: true,
                  ),
                  const SizedBox(height: 28),
                ],
                if (isIos) ...[
                  Text(
                    'iOS',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Browser scroll-blocking is implemented for Android first. '
                    'iOS Safari support will follow in a later update.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: SessionCutColors.muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
                Text(
                  'How it works',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The Accessibility service watches the browser URL. '
                  'Opening a Short is silent. Changing to a different Short id '
                  'pauses playback and shows the overlay. '
                  'This app does not open the video — playback stays in the browser.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: SessionCutColors.muted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.number,
    required this.text,
    this.isLast = false,
  });

  final String number;
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              number,
              style: textTheme.titleSmall?.copyWith(
                color: SessionCutColors.accent,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                color: SessionCutColors.text,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
