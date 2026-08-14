import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScanButton(),
            SizedBox(width: 16),
            SendButton(),
            SizedBox(width: 16),
            DisconnectButton(),
          ],
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
            return ListView.builder(
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  title: Text(device.advName),
                  subtitle: Text(device.remoteId.toString()),
                  trailing: BluetoothDeviceButton(device: device),
                );
              },
            );
          },
        ),
      ],
    );
  }
}


class ScanButton extends StatelessWidget {
  const ScanButton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isDark ? AppTheme.darkButtonBg : AppTheme.lightButtonBg;

    return Material(
      color: buttonColor,
      borderRadius: BorderRadius.circular(4),
      child: IconButton(
        icon: const Icon(Icons.bluetooth_searching),
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