import 'package:flutter/material.dart';

import 'features/setup/setup_screen.dart';

class YtScrollingKillerApp extends StatelessWidget {
  const YtScrollingKillerApp({super.key});

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
      home: const SetupScreen(),
    );
  }
}
