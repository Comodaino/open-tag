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
  static const Color brandPurple = Color.fromARGB(255, 157, 0, 255);
  static const Color brandPurpleDark = Color.fromARGB(255, 101, 2, 176);

  // Dark mode surfaces
  static const Color darkPanelBg = Color.fromARGB(255, 33, 33, 33); // main card
  static const Color darkBarBg = Color.fromARGB(255, 55, 55, 55); // floating bar
  static const Color darkScaffoldBg = Color.fromARGB(255, 25, 25, 25);
  static const Color darkButtonBg = Color.fromARGB(255, 82, 76, 95);
  static const Color darkButtonFg = Color.fromARGB(255, 219, 198, 231);
  // Light mode surfaces
  static const Color lightPanelBg = Color.fromARGB(255, 236, 236, 236);
  static const Color lightBarBg = Color.fromARGB(255, 189, 189, 189);
  static const Color lightScaffoldBg = Color.fromARGB(255, 245, 245, 245);
  static const Color lightButtonBg = Color.fromARGB(255, 255, 255, 255);
  static const Color lightButtonFg = Color.fromARGB(255, 171, 150, 183);

  // Utility colors
  static const Color errorRed = Color.fromARGB(255, 211, 88, 88);
  static const Color successGreen = Color.fromARGB(255, 104, 142, 104);
  static const Color warningYellow = Color.fromARGB(255, 225, 205, 125);
  static const Color white = Color.fromARGB(255, 245, 228, 255);
  static const Color black = Color.fromARGB(255, 17, 17, 18);


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
