import 'package:flutter/material.dart';

/// Centralized theme configuration for the app.
/// Edit the colors/typography here to restyle the whole app.
class AppTheme extends ChangeNotifier {
  bool isDark = true;
  static final AppTheme _instance = AppTheme._internal();
  AppTheme._internal();

  factory AppTheme() {
    return _instance;
  }

  // Brand colors
  static const Color brandPurple = Color(0xFF9C00FF); // image placeholder
  static const Color brandPurpleDark = Color.fromRGBO(100, 1, 177, 1);

  // Dark mode surfaces
  static const Color darkPanelBg = Color.fromARGB(255, 33, 33, 33); // main card
  static const Color darkBarBg = Color.fromARGB(255, 55, 55, 55); // floating bar
  static const Color darkScaffoldBg = Color.fromARGB(255, 25, 25, 25);
  static const Color darkButtonBg = Color.fromRGBO(82, 76, 95, 1);
  static const Color darkButtonFg = Color.fromARGB(255, 219, 198, 231);
  // Light mode surfaces
  static const Color lightPanelBg = Color(0xFFECECEC);
  static const Color lightBarBg = Color(0xFFBDBDBD);
  static const Color lightScaffoldBg = Color(0xFFF5F5F5);
  static const Color lightButtonBg = Color(0xFFFFFFFF);
  static const Color lightButtonFg = Color.fromARGB(255, 171, 150, 183);

  // Utility colors
  static const Color errorRed = Color.fromARGB(255, 211, 88, 88);
  static const Color successGreen = Color.fromARGB(255, 104, 142, 104);

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

  void toggleTheme() {
    isDark = !isDark;
    notifyListeners();
  }
}
