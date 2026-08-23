import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:open_tag_app/widgets/connected_device.dart';
import '../theme/app_theme.dart';
import '../utils/bt_utils.dart';

class BluetoothConnectionScreen extends StatefulWidget {
  final ThemeMode themeMode;

  const BluetoothConnectionScreen({
    super.key,
    required this.themeMode,
  });

  @override
  State<BluetoothConnectionScreen> createState() => _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;
    final titleColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.portrait) {
            return _PortraitLayout(
              titleColor: titleColor,
              isDark: isDark,
            );
          } else {
            return _LandscapeLayout(
              titleColor: titleColor,
              isDark: isDark,
            );
          }
        },
      ),
    );
  }
}


/// Landscape: side bar on the left, title + centered image on the right.
class _LandscapeLayout extends StatelessWidget {
  final Color titleColor;
  final bool isDark;


  const _LandscapeLayout({
    required this.titleColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        Text(
          'open-tag',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: titleColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        const ScanButton(),
      ],
    );
  }
}

class _PortraitLayout extends StatelessWidget {
  final Color titleColor;
  final bool isDark;
  const _PortraitLayout({
    required this.titleColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        Text(
          'open-tag',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: titleColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.darkPanelBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black54),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16,
            children: [
              ScanButton(),
              SendButton(),
              DisconnectButton(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Display the possible empty list of Bluetooth devices
        ListenableBuilder(
          listenable: BluetoothManager(),
          builder: (context, child) {
            final devices = BluetoothManager().getDiscoveredDevices();
            if (devices.isEmpty) {
              return const Center(
                child: Text('No devices found. Tap the scan button to search.'),
              );
            }
            return Flexible(
            child : ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 80),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkPanelBg : AppTheme.lightPanelBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black87, width: 2),
                  ),
                  child: ListTile(
                    title: Text(device.advName != ""? device.advName : device.remoteId.toString()),
                    subtitle: Text(device.advName != ""? device.remoteId.toString() : "device name not available"),
                    trailing: BluetoothDeviceButton(device: device),
                  )
                );
              }
            )
            );
          },
        ),
        const SizedBox(height: 20),
        const ConnectedDeviceBar(),
        const SizedBox(height: 60),
      ],
    );
  }
}


class ScanButton extends StatelessWidget {
  const ScanButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isDark ? AppTheme.darkButtonBg : AppTheme.lightButtonBg;

    return Material(
      color: buttonColor,
      borderRadius: BorderRadius.circular(4),
      child: IconButton(
        icon: const Icon(Icons.bluetooth_searching),
        color: isDark ? AppTheme.darkButtonFg : AppTheme.lightButtonFg,
        onPressed: () async {
          await BluetoothManager().scanForDevices();
        },
      ),
    );
  }
}

class DisconnectButton extends StatelessWidget {
  const DisconnectButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isDark ? AppTheme.darkButtonBg : AppTheme.lightButtonBg;

    return Material(
      color: buttonColor,
      borderRadius: BorderRadius.circular(4),
      child: IconButton(
        icon: const Icon(Icons.bluetooth_disabled),
        color: isDark ? AppTheme.darkButtonFg : AppTheme.lightButtonFg,
        onPressed: () async {
          await BluetoothManager().disconnectFromDevice();
        },
      ),
    );
  }
}

class SendButton extends StatelessWidget {
  const SendButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isDark ? AppTheme.darkButtonBg : AppTheme.lightButtonBg;

    return Material(
      color: buttonColor,
      borderRadius: BorderRadius.circular(4),
      child: IconButton(
        icon: const Icon(Icons.send),
        color: isDark ? AppTheme.darkButtonFg : AppTheme.lightButtonFg,
        onPressed: () async {
          print("Sending image to connected device: ${BluetoothManager().getConnectedDevice()?.remoteId}");
          await BluetoothManager().sendImage();
        },
      ),
    );
  }
}


class BluetoothDeviceButton extends StatelessWidget {
  final BluetoothDevice device;

  const BluetoothDeviceButton({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'connect_button_${device.remoteId}', // Unique hero tag for each device
      // The onPressed logic goes directly here
      onPressed: () async {
        await BluetoothManager().connectToDevice(device);
        print('Connected to device: ${device.remoteId}');
      },
      child: const Icon(Icons.bluetooth),
    );
  }
}