import 'package:flutter/material.dart';
import '../screens/bluetooth_screen.dart';
import '../theme/app_theme.dart';

/// A single action definition. Wire up [onTap] to real behavior later —
/// for now these are placeholders.
class ActionBarItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
 
  const ActionBarItem({
    required this.icon,
    required this.label,
    this.onTap,
  });
}

enum ActionBarLayout {
  /// Vertical stack of buttons — used in landscape mode as a side bar.
  sidebar,

  /// 2-column grid of buttons — used in portrait mode as a bottom bar.
  grid,
}

/// Floating bar of action buttons. Swap [layout] depending on
/// orientation to match the sidebar (landscape) / grid (portrait) design.
class FloatingActionBar extends StatelessWidget {
  final ActionBarLayout layout;

  void _navToBluetoothScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BluetoothConnectionScreen(themeMode: Theme.of(context).brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light),
      ),
    );
  }
 

  const FloatingActionBar({
    super.key,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark ? AppTheme.darkBarBg : AppTheme.lightBarBg;
    final List<ActionBarItem> items = [
      ActionBarItem(icon: Icons.add, label: 'Bluetooth Device', onTap: () => _navToBluetoothScreen(context)),
      const ActionBarItem(icon: Icons.share_outlined, label: 'Action 2', onTap: null),
      const ActionBarItem(icon: Icons.download_outlined, label: 'Action 3', onTap: null),
      const ActionBarItem(icon: Icons.settings_outlined, label: 'Action 4', onTap: null),
    ];

    late final Widget content;
    if (layout == ActionBarLayout.sidebar) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            FloatingActionButton(
              onPressed: items[i].onTap,
              heroTag: 'action_button_$i',
              child: Icon(items[i].icon), // Unique hero tag for each button
            ),
            if (i != items.length - 1) const SizedBox(height: 8),
          ],
        ],
      );
    } else {
      content = SizedBox(
        width: 320,
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.3,
          children: items
              .map((item) => FloatingActionButton(
                    onPressed: item.onTap,
                    child: Icon(item.icon),
                    heroTag: 'action_button_${item.label}', // Unique hero tag for each button
                  ))
              .toList(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black54),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: content,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final ActionBarItem item;
  final double? width;

  const _ActionButton({required this.item, this.width});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isDark ? AppTheme.darkButtonBg : AppTheme.lightButtonBg;

    return Material(
      color: buttonColor,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: item.onTap ??
            () {
              // Placeholder action — replace with real behavior.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.label} tapped')),
              );
              if (item.label == 'Bluetooth Device') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BluetoothConnectionScreen(themeMode: Theme.of(context).brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light)),
                );
              }
            },
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: const Color(0xFF2B2B2B), size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    color: Color(0xFF2B2B2B),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
