import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const OpenTagApp());
}

class OpenTagApp extends StatefulWidget {
  const OpenTagApp({super.key});

  @override
  State<OpenTagApp> createState() => _OpenTagAppState();
}

class _OpenTagAppState extends State<OpenTagApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'open-tag',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: HomeScreen(
        themeMode: _themeMode,
        onThemeToggle: () {
          setState(() {
            _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
          });
        },
      ),
    );
  }
}
