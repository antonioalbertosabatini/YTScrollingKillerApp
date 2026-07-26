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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _a11yChannel = MethodChannel(
    'com.ytscrollingkiller.ytscrolling_killer/accessibility',
  );

  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _cutWidth;

  bool? _guardEnabled;
  bool _statusLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    if (!kIsWeb && Platform.isAndroid) {
      _refreshGuardStatus();
    }
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !kIsWeb &&
        Platform.isAndroid) {
      _refreshGuardStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _refreshGuardStatus() async {
    if (!Platform.isAndroid) return;
    setState(() => _statusLoading = true);
    try {
      final enabled =
          await _a11yChannel.invokeMethod<bool>('isAccessibilityServiceEnabled');
      if (!mounted) return;
      setState(() {
        _guardEnabled = enabled ?? false;
        _statusLoading = false;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _guardEnabled = null;
        _statusLoading = false;
      });
    }
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        children: [
          const _SessionAtmosphere(),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          SessionCutSpace.lg,
                          28,
                          SessionCutSpace.lg,
                          SessionCutSpace.md,
                        ),
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
                              final maxWidth =
                                  MediaQuery.sizeOf(context).width * 0.28;
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: maxWidth *
                                      _cutWidth.value.clamp(0.0, 1.0),
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: SessionCutColors.accent,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: SessionCutSpace.xl),
                          Text(
                            'One Short, then stop',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.4,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: SessionCutSpace.sm),
                          Text(
                            'Watch one Short in your browser. Scroll to another '
                            'and the session cuts — pause, block, close the tab.',
                            style: textTheme.bodyLarge?.copyWith(
                              color: SessionCutColors.muted,
                              height: 1.45,
                            ),
                          ),
                          if (isAndroid) ...[
                            const SizedBox(height: SessionCutSpace.xl),
                            _GuardStatusCard(
                              enabled: _guardEnabled,
                              loading: _statusLoading,
                            ),
                            const SizedBox(height: SessionCutSpace.xl),
                            Text(
                              'Get started',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: SessionCutSpace.md),
                            const _SetupStep(
                              number: '1',
                              text: 'Enable the Shorts Guard service.',
                            ),
                            const _SetupStep(
                              number: '2',
                              text: 'Open a Short in Chrome (or another '
                                  'supported browser).',
                            ),
                            const _SetupStep(
                              number: '3',
                              text: 'Scroll to another Short — the block '
                                  'appears. Tap Close tab.',
                              isLast: true,
                            ),
                            const SizedBox(height: SessionCutSpace.lg),
                            ExpansionTile(
                              title: Text(
                                'How it works',
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: SessionCutColors.text,
                                ),
                              ),
                              children: [
                                Text(
                                  'The Accessibility service watches the browser '
                                  'URL. Opening a Short is silent. Changing to a '
                                  'different Short id pauses playback and shows '
                                  'the overlay. Playback stays in the browser — '
                                  'this app never opens the video.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: SessionCutColors.muted,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (isIos) ...[
                            const SizedBox(height: SessionCutSpace.xl),
                            const _IosComingLaterCard(),
                          ],
                        ],
                      ),
                    ),
                    if (isAndroid)
                      _StickyCtaBar(
                        guardEnabled: _guardEnabled == true,
                        bottomInset: bottomInset,
                        onPressed: () => _openAccessibilitySettings(context),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionAtmosphere extends StatelessWidget {
  const _SessionAtmosphere();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.55, -0.85),
            radius: 1.15,
            colors: [
              Color(0x332A1A16),
              SessionCutColors.ink,
            ],
            stops: [0.0, 0.72],
          ),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: MediaQuery.sizeOf(context).height * 0.35,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x66160C0A),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuardStatusCard extends StatelessWidget {
  const _GuardStatusCard({
    required this.enabled,
    required this.loading,
  });

  final bool? enabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isOn = enabled == true;
    final statusColor =
        isOn ? SessionCutColors.success : SessionCutColors.accent;
    final title = loading
        ? 'Checking Shorts Guard…'
        : isOn
            ? 'Shorts Guard is on'
            : 'Shorts Guard is off';
    final subtitle = loading
        ? 'Reading Accessibility settings'
        : isOn
            ? 'You’re set — open a Short in Chrome.'
            : 'Turn it on so scrolling to another Short gets cut.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SessionCutSpace.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isOn
                    ? Icons.check_circle_rounded
                    : Icons.shield_outlined,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: SessionCutSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: SessionCutColors.muted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IosComingLaterCard extends StatelessWidget {
  const _IosComingLaterCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(SessionCutSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coming later on iOS',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: SessionCutSpace.xs),
            Text(
              'Browser scroll-blocking ships on Android first. '
              'Safari support will follow in a later update.',
              style: textTheme.bodyMedium?.copyWith(
                color: SessionCutColors.muted,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyCtaBar extends StatelessWidget {
  const _StickyCtaBar({
    required this.guardEnabled,
    required this.bottomInset,
    required this.onPressed,
  });

  final bool guardEnabled;
  final double bottomInset;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SessionCutColors.ink.withValues(alpha: 0.92),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          SessionCutSpace.lg,
          SessionCutSpace.sm,
          SessionCutSpace.lg,
          SessionCutSpace.md + bottomInset,
        ),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: SessionCutColors.outline),
          ),
        ),
        child: guardEnabled
            ? OutlinedButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.settings_accessibility_rounded),
                label: const Text('Open Accessibility again'),
              )
            : FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.shield_rounded),
                label: const Text('Turn on Shorts Guard'),
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
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SessionCutColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              number,
              style: textTheme.labelLarge?.copyWith(
                color: SessionCutColors.accent,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: SessionCutSpace.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: textTheme.bodyMedium?.copyWith(
                  color: SessionCutColors.text,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
