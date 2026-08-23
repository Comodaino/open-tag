import 'package:flutter/material.dart';
import 'package:open_tag_app/widgets/connected_device.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? AppTheme.darkPanelBg : AppTheme.lightPanelBg;
    final titleColor = isDark ? Colors.white : const Color(0xFF2B2B2B);

    return Scaffold(
      body: SafeArea(
        child: Center(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: panelColor,
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: OrientationBuilder(
                builder: (context, orientation) {
                  return orientation == Orientation.landscape
                      ? _LandscapeLayout(
                          titleColor: titleColor,
                          onToggleTheme: onToggleTheme,
                          isDark: isDark,
                        )
                      : _PortraitLayout(
                          titleColor: titleColor,
                          onToggleTheme: onToggleTheme,
                          isDark: isDark,
                        );
                },
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 48),
        Text(
          'Open Tag',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: titleColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        IconButton(
          tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
          onPressed: onToggleTheme,
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            color: titleColor,
          ),
        ),
      ],
    );
  }
}

/// Landscape: side bar on the left, title + centered image on the right.
class _LandscapeLayout extends StatelessWidget {
  final Color titleColor;
  final VoidCallback onToggleTheme;
  final bool isDark;

  const _LandscapeLayout({
    required this.titleColor,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: FloatingActionBar(layout: ActionBarLayout.sidebar),
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
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
                        child: ImagePlaceholder(),
                      )
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
  final VoidCallback onToggleTheme;
  final bool isDark;

  const _PortraitLayout({
    required this.titleColor,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _TitleBar(
          titleColor: titleColor,
          onToggleTheme: onToggleTheme,
          isDark: isDark,
          fontSize: 20,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ImagePlaceholder(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: const FloatingActionBar(layout: ActionBarLayout.grid),
        ),
        const ConnectedDeviceBar(),
      ],
    );
  }
}
