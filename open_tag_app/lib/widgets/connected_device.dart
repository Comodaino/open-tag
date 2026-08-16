import 'package:flutter/material.dart';
import 'package:open_tag_app/theme/app_theme.dart';
import 'package:open_tag_app/utils/bt_utils.dart';

class ConnectedDeviceBar extends StatelessWidget {
  const ConnectedDeviceBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BluetoothManager(),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: BluetoothManager().getConnectedDevice() != null ? AppTheme.successGreen : AppTheme.errorRed,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              BluetoothManager().getConnectedDevice() != null
                  ? 'Connected to: ${BluetoothManager().getConnectedDevice()?.advName == "" ? BluetoothManager().getConnectedDevice()?.remoteId : BluetoothManager().getConnectedDevice()?.advName}'
                  : 'No device connected',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

}