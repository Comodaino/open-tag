import 'package:flutter/material.dart';
import 'package:open_tag_app/utils/bt_utils.dart';
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
  final VoidCallback onThemeToggle;

  const FloatingActionBar({
    super.key,
    required this.layout,
    required this.onThemeToggle,
  });

  void _navToBluetoothScreen(BuildContext context) {
    Navigator.push(
      context,
        MaterialPageRoute(
          builder: (context) => BluetoothConnectionScreen(onThemeToggle: onThemeToggle),
      ),
    );
  }
  
  void _sendImage() {
    if (BluetoothManager().getConnectedDevice() != null) {
      BluetoothManager().sendImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<ActionBarItem> items = [
      ActionBarItem(icon: Icons.add, label: 'Bluetooth Device', onTap: () => _navToBluetoothScreen(context)),
      ActionBarItem(icon: Icons.send, label: 'Send Image', onTap: () => _sendImage()),
      const ActionBarItem(icon: Icons.settings_outlined, label: 'Image settings', onTap: null),
      const ActionBarItem(icon: Icons.picture_in_picture_outlined, label: 'Picture of the day', onTap: null),
    ];

    late final Widget content;
    if (layout == ActionBarLayout.sidebar) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            SizedBox(
              width: 160,
              child: 
                FloatingActionButton(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkButtonBg : AppTheme.lightButtonBg,
                  foregroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkButtonFg : AppTheme.lightButtonFg,
                  onPressed: items[i].onTap,
                  heroTag: 'action_button_$i',
                  child: Row (
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(width: 8),
                      Icon(items[i].icon),
                      const SizedBox(width: 4),
                      Text(
                        items[i].label,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            if (i != items.length - 1) const SizedBox(height: 8),
          ],
        ],
      );
    } else {
      content = GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.3,
        mainAxisExtent: 80,
        children: items
            .map((item) => FloatingActionButton(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkButtonBg : AppTheme.lightButtonBg,
                  foregroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkButtonFg : AppTheme.lightButtonFg,
                  onPressed: item.onTap, 
                  heroTag: 'action_button_${item.label}',
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ), // Unique hero tag for each button
                ))
            .toList(),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBarBg : AppTheme.lightBarBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: ListenableBuilder(
        listenable: BluetoothManager(),
        builder: (context, child) {
          return content;
        }
      )
    );
  }
}