import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../theme/app_theme.dart';
import 'dart:typed_data';
import 'tmp_payload.dart';

class BluetoothConnectionScreen extends StatefulWidget {
  final ThemeMode themeMode;

  BluetoothConnectionScreen({
    super.key,
    required this.themeMode,
  });

  @override
  State<BluetoothConnectionScreen> createState() => _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  List<BluetoothDeviceButton> _devices = [];    
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
              owner: this,
            );
          } else {
            return _LandscapeLayout(
              titleColor: titleColor,
              isDark: isDark,
              owner: this,
            );
          }
        },
      ),
    );
  }

  _addDevice(BluetoothDeviceButton device) {
    if (_devices.any((d) => d.device.remoteId == device.device.remoteId)) {
      // Device already exists, do not add it again
      return;
    }
    _devices.add(device);
    setState(() {}); // Trigger a rebuild to update the UI
  }
  getDevices() {
    return _devices;
  }
}


/// Landscape: side bar on the left, title + centered image on the right.
class _LandscapeLayout extends StatelessWidget {
  final Color titleColor;
  final bool isDark;
  final _BluetoothConnectionScreenState owner;


  _LandscapeLayout({
    required this.titleColor,
    required this.isDark,
    required this.owner,
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
        _ScanButton(owner: owner),
      ],
    );
  }
}

class _PortraitLayout extends StatelessWidget {
  final Color titleColor;
  final bool isDark;
  final _BluetoothConnectionScreenState owner;
  _PortraitLayout({
    required this.titleColor,
    required this.isDark,
    required this.owner,
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
        _ScanButton(owner: owner),
        const SizedBox(height: 16),
        // Display the possible empty list of Bluetooth devices
        Expanded(
          child: ListView.builder(
            itemCount: owner.getDevices().length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(owner.getDevices()[index].device.advName),
                subtitle: Text(owner.getDevices()[index].device.remoteId.toString()),
                trailing: owner.getDevices()[index],
              );
            },
          ),
        ),
      ],
    );
  }
}


class _ScanButton extends StatelessWidget {
  _ScanButton({super.key, required this.owner});
  final _BluetoothConnectionScreenState owner;

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
          print("Scan button pressed");
          if (await FlutterBluePlus.isSupported == false) {
              print("Bluetooth not supported by this device");
              return;
          }
          print("Bluetooth is supported by this device");

          // handle bluetooth on & off
          // note: for iOS the initial state is typically BluetoothAdapterState.unknown
          // note: if you have permissions issues you will get stuck at BluetoothAdapterState.unauthorized
          var subscription = FlutterBluePlus.onScanResults.listen((results) {
                  if (results.isNotEmpty) {
                      ScanResult r = results.last; // the most recently found device
                      print('${r.device.remoteId}: "${r.advertisementData.advName}" found!');
                      owner._addDevice(BluetoothDeviceButton(device: r.device));
                  }
              },
              onError: (e) => print(e),
          );

          // cleanup: cancel subscription when scanning stops
          FlutterBluePlus.cancelWhenScanComplete(subscription);

          // Wait for Bluetooth enabled & permission granted
          // In your real app you should use `FlutterBluePlus.adapterState.listen` to handle all states
          await FlutterBluePlus.adapterState.where((val) => val == BluetoothAdapterState.on).first;

          // Start scanning w/ timeout
          // Optional: use `stopScan()` as an alternative to timeout
          print("Starting scan for Bluetooth devices...");
          await FlutterBluePlus.startScan(
            // withServices:[Guid("180D")], // match any of the specified services
            // withNames:["Bluno"], // *or* any of the specified names
            timeout: Duration(seconds:15));

          // wait for scanning to stop
          await FlutterBluePlus.isScanning.where((val) => val == false).first;

          // turn on bluetooth ourself if we can
          // for iOS, the user controls bluetooth enable/disable
          // if (!kIsWeb && Platform.isAndroid) {
          //     await FlutterBluePlus.turnOn();
          // }

          // cancel to prevent duplicate listeners
          subscription.cancel();

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
      // The onPressed logic goes directly here
      onPressed: () async {
        print("Connecting to device ${device.advName} with ID ${device.remoteId}");
        // Trigger your BLE connection logic here

        // listen for disconnection
        var subscription = device.connectionState.listen((BluetoothConnectionState state) async {
            if (state == BluetoothConnectionState.disconnected) {
                // 1. typically, start a periodic timer that tries to 
                //    reconnect, or just call connect() again right now
                // 2. you must always re-discover services after disconnection!
                print("Device disconnected.");
                print("${device.disconnectReason?.code} ${device.disconnectReason?.description}");
            }
        });

        // cleanup: cancel subscription when disconnected
        //   - [delayed] This option is only meant for `connectionState` subscriptions.  
        //     When `true`, we cancel after a small delay. This ensures the `connectionState` 
        //     listener receives the `disconnected` event.
        //   - [next] if true, the the stream will be canceled only on the *next* disconnection,
        //     not the current disconnection. This is useful if you setup your subscriptions
        //     before you connect.
        device.cancelWhenDisconnected(subscription, delayed:true, next:true);

        // Connect to the device
        await device.connect(license: License.nonprofit);

        print("Discovering services for device ${device.advName}...");
        // Discover services
        List<BluetoothService> services = await device.discoverServices();
        print("Discovered ${services.length} services for device ${device.advName}.");
        for (var service in services) {
            print("Service UUID: ${service.uuid}");
            for (var characteristic in service.characteristics) {
                print("  Characteristic UUID: ${characteristic.uuid}");
            }
        }

        BluetoothCharacteristic? rxCharacteristic;
        // 1. Locate the Nordic UART Service and the RX Characteristic
        for (var service in services) {
          // Check for Nordic UART Service
          if (service.uuid == Guid("6e400001-b5a3-f393-e0a9-e50e24dcca9e")) {
            for (var characteristic in service.characteristics) {
              // Check for RX Characteristic (Write)
              if (characteristic.uuid == Guid("6e400002-b5a3-f393-e0a9-e50e24dcca9e")) {
                rxCharacteristic = characteristic;
                break; // Found it, exit inner loop
              }
            }
          }
        }

        // 2. Send the data if the characteristic was found
        if (rxCharacteristic != null) {

          // The default safe payload size for BLE is 20 bytes per packet.
          // If you negotiate a higher MTU, you can increase this to ~244.
          int chunkSize = 200; 

          try {

            BytesBuilder packetBuilder = BytesBuilder();

            // --- ADD HEADER ---
            packetBuilder.addByte(0x21); // ASCII '!'
            packetBuilder.addByte(0x49); // ASCII 'I'
            packetBuilder.addByte(24);
            // Add width (uint16 -> split into 2 uint8 bytes, Little-Endian)
            packetBuilder.addByte(200 & 0xFF);
            packetBuilder.addByte((200 >> 8) & 0xFF);
            // Add height (uint16 -> split into 2 uint8 bytes, Little-Endian)
            packetBuilder.addByte(200 & 0xFF);
            packetBuilder.addByte((200 >> 8) & 0xFF);
            packetBuilder.add(payloadImg); // Add the image payload

            Uint8List packetWithoutCrc = packetBuilder.toBytes();

            int crc = 0;
            for (int byte in packetWithoutCrc) {
              crc = crc ^ byte; // Simple XOR checksum
            }
            print("Calculated CRC: $crc");

            // Add the final CRC byte
            packetBuilder.addByte(crc);
            print("Final packet with CRC: ${packetBuilder.toBytes()}");

            Uint8List finalPacketToSend = packetBuilder.toBytes();
            print("Sending ${finalPacketToSend.length} bytes to MCU...");
            for (int i = 0; i < finalPacketToSend.length; i += chunkSize) {
              // Calculate the end of the current chunk
              int end = (i + chunkSize < finalPacketToSend.length) ? i + chunkSize : finalPacketToSend.length;
              
              // Extract the chunk
              Uint8List chunk = Uint8List.fromList(finalPacketToSend.sublist(i, end));

              // Write the chunk to the MCU
              await rxCharacteristic.write(chunk, withoutResponse: false);

              // CRITICAL: Give the MCU a tiny window to process the incoming buffer.
              // If you blast packets in a tight loop with `withoutResponse`, 
              // the MCU's BLE stack will overflow and drop bytes.
             //await Future.delayed(const Duration(milliseconds: 10)); 
            }

            print("Bitstream successfully sent!");

          } catch (e) {
            print("Error sending data: $e");
          }
        }

        // Disconnect from device
        await device.disconnect();

        // cancel to prevent duplicate listeners
        subscription.cancel();
      },
      child: const Icon(Icons.bluetooth),
    );
  }
}