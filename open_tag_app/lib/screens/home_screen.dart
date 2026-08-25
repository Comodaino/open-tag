import 'package:flutter/material.dart';
import 'package:open_tag_app/widgets/connected_device.dart';
import 'package:open_tag_app/widgets/progress_bar.dart';
import 'package:open_tag_app/widgets/top_floating_bar.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_action_bar.dart';
import '../widgets/image_placeholder.dart';

class HomeScreen extends StatelessWidget {
  final ThemeMode themeMode;
  final VoidCallback onThemeToggle;

  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = Theme.of(context).brightness == Brightness.dark ? AppTheme.darkScaffoldBg : AppTheme.lightScaffoldBg;

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
                          isDark: isDark,
                          onThemeToggle: onThemeToggle,
                        )
                      : _PortraitLayout(
                          isDark: isDark,
                          onThemeToggle: onThemeToggle,
                        );
                },
              ),
            ),
        ),
      ),
    );
  }
}

/// Landscape: side bar on the left, title + centered image on the right.
class _LandscapeLayout extends StatelessWidget {
  final bool isDark;
  final VoidCallback onThemeToggle;

  const _LandscapeLayout({
    required this.isDark,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children:[ 
        TopFloatingBar(onThemeToggle: onThemeToggle),
        Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: const ConnectedDeviceBar(),
        ),
        const ProgressBar(),
        const SizedBox(height: 24),
        Stack(
          alignment: Alignment.topCenter,
          children: [
            // Left and right children, pinned to the edges
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                FloatingActionBar(layout: ActionBarLayout.sidebar, onThemeToggle: onThemeToggle),
                const SizedBox(width: 16),
              ],
            ),
            // Middle child, always centered on the full width
            Align(
              alignment: Alignment.center,
              child: Container(
                  constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ImagePlaceholder(),
                  ),
                ),
            ),
          ],
        ),
      ]
    );
  }
}

/// Portrait: title on top, centered image, action grid pinned to the bottom.
class _PortraitLayout extends StatelessWidget {
  final bool isDark;
  final VoidCallback onThemeToggle;

  const _PortraitLayout({
    required this.isDark,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TopFloatingBar(onThemeToggle: onThemeToggle),
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
        const ProgressBar(),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: FloatingActionBar(layout: ActionBarLayout.grid, onThemeToggle: onThemeToggle),
        ),
        const ConnectedDeviceBar(),
      ],
    );
  }
}
