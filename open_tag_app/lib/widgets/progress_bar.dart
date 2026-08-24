import 'package:flutter/material.dart';
import 'package:open_tag_app/theme/app_theme.dart';
import 'package:open_tag_app/utils/bt_utils.dart';

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BluetoothManager(),
      builder: (context, child) {
        return BluetoothManager().imgTxProgress != 0 ? Container(
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.brandPurple.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: LinearProgressIndicator(
            value: BluetoothManager().imgTxProgress,
            backgroundColor: AppTheme.brandPurpleDark,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.brandPurple),
          ),
        ) : const SizedBox(height: 20);
      },
    );
  }
}