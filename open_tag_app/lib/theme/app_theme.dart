import 'package:flutter/material.dart';

/// Centralized theme configuration for the app.
/// Edit the colors/typography here to restyle the whole app.
class AppTheme {
  AppTheme._();

  // Brand colors
  static const Color brandPurple = Color(0xFF9C00FF); // image placeholder
  static const Color brandPurpleDark = Color(0xFF6E00C4);

  // Dark mode surfaces
  static const Color darkPanelBg = Color(0xFF3D3D3D); // main card
  static const Color darkBarBg = Color(0xFF6E6E6E); // floating bar
  static const Color darkScaffoldBg = Color(0xFF1E1E1E);
  static const Color darkButtonBg = Color(0xFF6E6E6E);
  static const Color darkButtonFg = Color(0xFFCEBED7);
  // Light mode surfaces
  static const Color lightPanelBg = Color(0xFFECECEC);
  static const Color lightBarBg = Color(0xFFBDBDBD);
  static const Color lightScaffoldBg = Color(0xFFF5F5F5);
  static const Color lightButtonBg = Color(0xFFFFFFFF);
  static const Color lightButtonFg = Color(0xFF9C00FF);

  // Utility colors
  static const Color errorRed = Color.fromARGB(255, 211, 88, 88);
  static const Color successGreen = Color.fromARGB(255, 87, 149, 87);

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandPurple,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: lightScaffoldBg,
        cardColor: lightPanelBg,
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      );

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: darkScaffoldBg,
        cardColor: darkPanelBg,
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      );
}
