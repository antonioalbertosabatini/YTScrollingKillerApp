import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/setup/setup_screen.dart';

/// Session cut palette — intentional stop, not generic setup chrome.
abstract final class SessionCutColors {
  static const ink = Color(0xFF0B0E11);
  static const surface = Color(0xFF161B22);
  static const text = Color(0xFFF2F0EB);
  static const muted = Color(0xFF9AA3AD);
  static const accent = Color(0xFFFF5A3D);
  static const accentSoft = Color(0xFFFF8A70);
}

class YtScrollingKillerApp extends StatelessWidget {
  const YtScrollingKillerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final display = GoogleFonts.spaceGroteskTextTheme();
    final body = GoogleFonts.dmSansTextTheme();

    final textTheme = body
        .copyWith(
          displayLarge: display.displayLarge,
          displayMedium: display.displayMedium,
          displaySmall: display.displaySmall,
          headlineLarge: display.headlineLarge,
          headlineMedium: display.headlineMedium,
          headlineSmall: display.headlineSmall,
          titleLarge: display.titleLarge,
          titleMedium: display.titleMedium,
          titleSmall: display.titleSmall,
        )
        .apply(
          bodyColor: SessionCutColors.text,
          displayColor: SessionCutColors.text,
        );

    final colorScheme = const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: SessionCutColors.accent,
      onPrimary: SessionCutColors.text,
      secondary: SessionCutColors.accentSoft,
      onSecondary: SessionCutColors.ink,
      surface: SessionCutColors.surface,
      onSurface: SessionCutColors.text,
      onSurfaceVariant: SessionCutColors.muted,
      outline: Color(0xFF2A313C),
    );

    return MaterialApp(
      title: 'YTScrollingKiller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: SessionCutColors.ink,
        textTheme: textTheme,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: SessionCutColors.accent,
            foregroundColor: SessionCutColors.text,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.dmSans(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
      home: const SetupScreen(),
    );
  }
}
