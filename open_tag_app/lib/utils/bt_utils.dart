import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'tmp_payload.dart';

class BluetoothManager extends ChangeNotifier {
  static final BluetoothManager _instance = BluetoothManager._internal();
  BluetoothDevice? connectedDevice;
  List<BluetoothDevice> discoveredDevices = [];
  List<BluetoothService> services = [];
  Uint8List? payload;

  BluetoothManager._internal();

  factory BluetoothManager() {
    return _instance;
  }

  Future<bool> scanForDevices() async {
    if (await FlutterBluePlus.isSupported == false) {
        print("Bluetooth not supported by this device");
        return false;
    }
    // Cancel previous scan if any
    if(FlutterBluePlus.isScanningNow) {
        print("Stopping previous scan...");
        await FlutterBluePlus.stopScan();
    }
    discoveredDevices.clear();
    print("Cleared discovered devices list.");
    notifyListeners(); // Notify listeners that the list of discovered devices has changed

    var subscription = FlutterBluePlus.onScanResults.listen((results) {
            if (results.isNotEmpty) {
                ScanResult r = results.last; // the most recently found device
                bool alreadyKnown = discoveredDevices
                    .any((d) => d.remoteId == r.device.remoteId);
                if (!alreadyKnown) {
                  print('${r.device.remoteId}: "${r.advertisementData.advName}" found!');
                  discoveredDevices.add(r.device);
                  notifyListeners(); // Notify listeners that the list of discovered devices has changed
                }
            }
        },
        onError: (e) => print(e),
    );

    // cleanup: cancel subscription when scanning stops
    FlutterBluePlus.cancelWhenScanComplete(subscription);

    // FIX: wait for Bluetooth to turn on, but don't hang forever if the
    // user never enables it / denies permission.
    try {
      await FlutterBluePlus.adapterState
          .where((val) => val == BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      print("Bluetooth adapter did not turn on in time.");
      await subscription.cancel();
      return false;
    }

    // Start scanning w/ timeout
    print("Starting scan for Bluetooth devices...");
    await FlutterBluePlus.startScan(
      // withServices:[Guid("6e400001-b5a3-f393-e0a9-e50e24dcca9e")], // match any of the specified services
      // withNames:["Bluno"], // *or* any of the specified names
      timeout: const Duration(seconds: 15));

    // wait for scanning to stop
    await FlutterBluePlus.isScanning.where((val) => val == false).first;

    subscription.cancel();
    return true;
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    print("Connecting to device ${device.advName} with ID ${device.remoteId}");
    final connected = await _connectAndDiscover(device);
    if (!connected) {
      return false;
    }

    var subscription = device.connectionState.listen((BluetoothConnectionState state) async {
        if (state == BluetoothConnectionState.disconnected) {
            print("Device disconnected.");
            print("${device.disconnectReason?.code} ${device.disconnectReason?.description}");
            try {
              await _connectAndDiscover(device);
            } catch (e) {
              print("Reconnect failed: $e");
            }
        }
    });

    device.cancelWhenDisconnected(subscription, delayed: true, next: true);

    return true;
  }

  Future<bool> _connectAndDiscover(BluetoothDevice device) async {
    try {
      if (FlutterBluePlus.isScanningNow) {
        print("Stopping active scan before connecting...");
        await FlutterBluePlus.stopScan();
      }

      print("Calling device.connect()...");
      await device.connect(
        license: License.nonprofit,
        timeout: const Duration(seconds: 15),
      );
      print("device.connect() returned — connected.");

      print("Discovering services for device ${device.advName}...");
      List<BluetoothService> discovered = await device.discoverServices();
      print("Discovered ${discovered.length} services for device ${device.advName}.");
      for (var service in discovered) {
          print("Service UUID: ${service.uuid}");
          for (var characteristic in service.characteristics) {
              print("  Characteristic UUID: ${characteristic.uuid}");
          }
      }

      connectedDevice = device;
      services = discovered;
      notifyListeners();
      return true;
    } catch (e) {
      print("Error connecting/discovering services: $e");
      return false;
    }
  }

  Future<void> disconnectFromDevice() async {
    if (connectedDevice != null) {
      print("Disconnecting from device ${connectedDevice!.advName}...");
      await connectedDevice!.disconnect();
      print("Disconnected with device ${connectedDevice!.advName}.");
      connectedDevice = null;
      services.clear();
      notifyListeners();
    }
  }

  Future<bool> sendImage() async {
    BluetoothCharacteristic? rxCharacteristic;
    // 1. Locate the Nordic UART Service and the RX Characteristic
    for (var service in services) {
      if (service.uuid == Guid("6e400001-b5a3-f393-e0a9-e50e24dcca9e")) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == Guid("6e400002-b5a3-f393-e0a9-e50e24dcca9e")) {
            rxCharacteristic = characteristic;
            break;
          }
        }
      }
    }

    if (rxCharacteristic == null) {
      print("RX characteristic not found — is the device connected and services discovered?");
      return false;
    }

    // The default safe payload size for BLE is 20 bytes per packet.
    // If you negotiate a higher MTU, you can increase this to ~244.
    int chunkSize = 200;

    try {
      if (payload == null) {
        print("No payload set — using default image.");
      }
      Uint8List packet = payload ?? setPayload(defaultPayloadImg);
      for (int i = 0; i < packet.length; i += chunkSize) {
        int end = (i + chunkSize < packet.length) ? i + chunkSize : packet.length;
        Uint8List chunk = Uint8List.fromList(packet.sublist(i, end));

        await rxCharacteristic.write(chunk, withoutResponse: false);

        // FIX (restored): give the MCU a brief window to process the
        // incoming buffer. Without this, tight-loop writes can overflow
        // the MCU's BLE stack and drop bytes, even with
        // `withoutResponse: false`.
        await Future.delayed(const Duration(milliseconds: 10));
      }

      print("Bitstream successfully sent!");
      return true;
    } catch (e) {
      print("Error sending data: $e");
      return false;
    }
  }

  getDiscoveredDevices() {
    return discoveredDevices;
  }

  getConnectedDevice() {
    return connectedDevice;
  }

  Uint8List setPayload(Uint8List newPayload) {
    BytesBuilder packetBuilder = BytesBuilder();

    // --- ADD HEADER ---
    packetBuilder.addByte(0x21); // ASCII '!'
    packetBuilder.addByte(0x49); // ASCII 'I'
    packetBuilder.addByte(24);
    packetBuilder.addByte(200 & 0xFF);
    packetBuilder.addByte((200 >> 8) & 0xFF);
    packetBuilder.addByte(200 & 0xFF);
    packetBuilder.addByte((200 >> 8) & 0xFF);
    packetBuilder.add(newPayload);

    Uint8List packetWithoutCrc = packetBuilder.toBytes();

    int crc = 0;
    for (int byte in packetWithoutCrc) {
      crc = crc ^ byte;
    }

    packetBuilder.addByte(crc);
    payload = packetBuilder.toBytes();
    notifyListeners();
    return packetBuilder.toBytes();
  }
}