import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/setup/setup_screen.dart';

/// Session cut palette — intentional stop, not generic setup chrome.
abstract final class SessionCutColors {
  static const ink = Color(0xFF0B0E11);
  static const surface = Color(0xFF161B22);
  static const surfaceElevated = Color(0xFF1C222B);
  static const text = Color(0xFFF2F0EB);
  static const muted = Color(0xFF9AA3AD);
  static const accent = Color(0xFFFF5A3D);
  static const accentSoft = Color(0xFFFF8A70);
  static const success = Color(0xFF3D9B84);
  static const outline = Color(0xFF2A313C);
}

abstract final class SessionCutSpace {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const radius = 16.0;
  static const radiusButton = 14.0;
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
      outline: SessionCutColors.outline,
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
        cardTheme: CardThemeData(
          color: SessionCutColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SessionCutSpace.radius),
            side: const BorderSide(color: SessionCutColors.outline),
          ),
          margin: EdgeInsets.zero,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: SessionCutColors.surfaceElevated,
          contentTextStyle: GoogleFonts.dmSans(
            color: SessionCutColors.text,
            fontSize: 14,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        expansionTileTheme: const ExpansionTileThemeData(
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          iconColor: SessionCutColors.muted,
          collapsedIconColor: SessionCutColors.muted,
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.only(top: SessionCutSpace.sm),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: SessionCutColors.accent,
            foregroundColor: SessionCutColors.text,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SessionCutSpace.radiusButton),
            ),
            textStyle: GoogleFonts.dmSans(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: SessionCutColors.text,
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: SessionCutColors.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SessionCutSpace.radiusButton),
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
