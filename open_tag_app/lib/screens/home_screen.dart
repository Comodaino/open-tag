import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_action_bar.dart';
import '../widgets/image_placeholder.dart';

class HomeScreen extends StatelessWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  List<ActionBarItem> get _items => const [
        ActionBarItem(icon: Icons.add, label: 'Bluetooth Device'),
        ActionBarItem(icon: Icons.share_outlined, label: 'Action 2'),
        ActionBarItem(icon: Icons.download_outlined, label: 'Action 3'),
        ActionBarItem(icon: Icons.settings_outlined, label: 'Action 4'),
      ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? AppTheme.darkPanelBg : AppTheme.lightPanelBg;
    final titleColor = isDark ? Colors.white : const Color(0xFF2B2B2B);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 720),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black87, width: 2),
                ),
                child: OrientationBuilder(
                  builder: (context, orientation) {
                    return orientation == Orientation.landscape
                        ? _LandscapeLayout(
                            titleColor: titleColor,
                            items: _items,
                            onToggleTheme: onToggleTheme,
                            isDark: isDark,
                          )
                        : _PortraitLayout(
                            titleColor: titleColor,
                            items: _items,
                            onToggleTheme: onToggleTheme,
                            isDark: isDark,
                          );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Top bar with the app title (open-tag) and a light/dark toggle button.
class _TitleBar extends StatelessWidget {
  final Color titleColor;
  final VoidCallback onToggleTheme;
  final bool isDark;
  final double fontSize;

  const _TitleBar({
    required this.titleColor,
    required this.onToggleTheme,
    required this.isDark,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          'open-tag',
          style: TextStyle(
            color: titleColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        Positioned(
          right: 0,
          child: IconButton(
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: onToggleTheme,
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: titleColor,
            ),
          ),
        ),
      ],
    );
  }
}

/// Landscape: side bar on the left, title + centered image on the right.
class _LandscapeLayout extends StatelessWidget {
  final Color titleColor;
  final List<ActionBarItem> items;
  final VoidCallback onToggleTheme;
  final bool isDark;

  const _LandscapeLayout({
    required this.titleColor,
    required this.items,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: FloatingActionBar(items: items, layout: ActionBarLayout.sidebar),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 24, top: 16, bottom: 24),
            child: Column(
              children: [
                _TitleBar(
                  titleColor: titleColor,
                  onToggleTheme: onToggleTheme,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                const Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ImagePlaceholder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Portrait: title on top, centered image, action grid pinned to the bottom.
class _PortraitLayout extends StatelessWidget {
  final Color titleColor;
  final List<ActionBarItem> items;
  final VoidCallback onToggleTheme;
  final bool isDark;

  const _PortraitLayout({
    required this.titleColor,
    required this.items,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _TitleBar(
            titleColor: titleColor,
            onToggleTheme: onToggleTheme,
            isDark: isDark,
            fontSize: 20,
          ),
          const SizedBox(height: 20),
          const Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: ImagePlaceholder(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FloatingActionBar(items: items, layout: ActionBarLayout.grid),
        ],
      ),
    );
  }
}
