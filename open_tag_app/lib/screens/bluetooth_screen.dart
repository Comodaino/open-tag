import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:open_tag_app/widgets/connected_device.dart';
import 'package:open_tag_app/widgets/progress_bar.dart';
import 'package:open_tag_app/widgets/top_floating_bar.dart';
import '../theme/app_theme.dart';
import '../utils/bt_utils.dart';

class BluetoothConnectionScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const BluetoothConnectionScreen({
    super.key,
    required this.onThemeToggle,
  });

  @override
  State<BluetoothConnectionScreen> createState() => _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
        body: SafeArea(
          child: Center(
            child: OrientationBuilder(
          builder: (context, orientation) {
            if (orientation == Orientation.portrait) {
              return _PortraitLayout(widget.onThemeToggle);
            } else {
              return _LandscapeLayout(widget.onThemeToggle);
            }
          },
        ),
          ),
      )
    );
  }
}


/// Landscape: side bar on the left, title + centered image on the right.
class _LandscapeLayout extends StatelessWidget {
  final VoidCallback onThemeToggle;

  const _LandscapeLayout(this.onThemeToggle );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopFloatingBar(onThemeToggle: onThemeToggle),
        Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: const ConnectedDeviceBar(),
        ),
        const ProgressBar(),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkPanelBg : AppTheme.lightPanelBg,
            borderRadius: BorderRadius.circular(12),
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
                  return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkPanelBg : AppTheme.lightPanelBg,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: ListTile(
                          title: Text(device.advName != ""? device.advName : device.remoteId.toString()),
                          subtitle: Text(device.advName != ""? device.remoteId.toString() : "device name not available"),
                          trailing: BluetoothDeviceButton(device: device),
                        )
                      )
                    )
                  );
                }
              )
            );
          },
        ),
        ListenableBuilder(
          listenable: BluetoothManager(),
          builder: (context, child) {
            return BluetoothManager().getDiscoveredDevices().isEmpty ? const Spacer() : const SizedBox(height: 10);
          },
        ),
      ],
    );
  }
}

class _PortraitLayout extends StatelessWidget {
  final VoidCallback onThemeToggle;

  const _PortraitLayout(this.onThemeToggle);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopFloatingBar(onThemeToggle: onThemeToggle),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkPanelBg : AppTheme.lightPanelBg,
            borderRadius: BorderRadius.circular(12),
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
                      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkPanelBg : AppTheme.lightPanelBg,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                      ],
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
        ListenableBuilder(
          listenable: BluetoothManager(),
          builder: (context, child) {
            return BluetoothManager().getDiscoveredDevices().isEmpty ? const Spacer() : const SizedBox(height: 10);
          },
        ),
        const ProgressBar(),
        const ConnectedDeviceBar(),
      ],
    );
  }
}


class ScanButton extends StatelessWidget {
  const ScanButton({super.key});

  @override
  Widget build(BuildContext context) {

    return Material(
      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkButtonBg : AppTheme.lightButtonBg,
      borderRadius: BorderRadius.circular(4),
      child: IconButton(
        icon: const Icon(Icons.bluetooth_searching),
        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkButtonFg : AppTheme.lightButtonFg,
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

    return Material(
      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkButtonBg : AppTheme.lightButtonBg ,
      borderRadius: BorderRadius.circular(4),
      child: IconButton(
        icon: const Icon(Icons.bluetooth_disabled),
        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkButtonFg : AppTheme.lightButtonFg,
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

    return Material(
      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkButtonBg : AppTheme.lightButtonBg ,
      borderRadius: BorderRadius.circular(4),
      child: IconButton(
        icon: const Icon(Icons.send),
        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkButtonFg : AppTheme.lightButtonFg,
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
      foregroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkButtonFg : AppTheme.lightButtonFg,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkButtonBg : AppTheme.lightButtonBg,
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