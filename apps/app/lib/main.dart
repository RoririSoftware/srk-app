import 'package:flutter/material.dart';

import 'screens/login.dart';
import 'ui.dart';

void main() => runApp(const SrkApp());

class SrkApp extends StatelessWidget {
  const SrkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SKR Trader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        canvasColor: canvas,
        colorScheme: ColorScheme.fromSeed(seedColor: accent, surface: canvas),
        splashFactory: NoSplash.splashFactory,
        appBarTheme: const AppBarTheme(
          backgroundColor: canvas,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: ink),
          titleTextStyle: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFFD3DBE4), thickness: 1, space: 1),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w800),
          titleMedium: TextStyle(color: ink, fontWeight: FontWeight.w700),
          bodyMedium: TextStyle(color: ink),
          bodySmall: TextStyle(color: muted),
        ),
      ),
      home: const LoginPage(),
    );
  }
}
