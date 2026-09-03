import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_tag_app/utils/material_banners.dart';
import 'package:open_tag_app/widgets/connected_device.dart';
import 'package:open_tag_app/widgets/progress_bar.dart';
import 'package:open_tag_app/widgets/top_floating_bar.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../utils/bt_utils.dart';

class POTDScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const POTDScreen({
    super.key,
    required this.onThemeToggle,
  });

  @override
  State<POTDScreen> createState() => _POTDScreenState();
}

class _POTDScreenState extends State<POTDScreen> {
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
        const NasaPOTDWidget(),

        const Spacer(),
        const SizedBox(height: 16),
        const ConnectedDeviceBar(),
      ],
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

class NasaPOTDWidget extends StatefulWidget {
  const NasaPOTDWidget({super.key});

  @override
  State<NasaPOTDWidget> createState() => _NasaPOTDWidgetState();
}

class _NasaPOTDWidgetState extends State<NasaPOTDWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _editingController = TextEditingController();
  _NasaPOTDWidgetState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Form(
        key: _formKey,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400), // give it a real bound
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkPanelBg
                : AppTheme.lightPanelBg,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextFormField(
                  controller: _editingController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    prefixIcon: const Icon(Icons.bento_rounded),
                    labelText: "Enter a new API key or press submit",
                  ),
                  validator: (value) {
                    return null;
                  },
                ),
                  
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.validate() == true) {
                      final storage = FlutterSecureStorage();
                      String? storedAPIKey = await storage.read(key: 'nasa_api_key');
                      if (storedAPIKey == null || storedAPIKey != _editingController.text) {
                        await storage.write(key: 'nasa_api_key', value: _editingController.text);
                        storedAPIKey = _editingController.text;
                      }

                      http.Response response = await http.get(Uri.parse("https://api.nasa.gov/planetary/apod?api_key=$storedAPIKey"));
                      if (response.statusCode != 200) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                        }
                        String errorMessage = "";
                        if (response.statusCode >= 400 && response.statusCode < 500) {
                          errorMessage = "Error: Invalid API key. Please check your NASA API key.";
                        } else if (response.statusCode >= 500 && response.statusCode < 600) {
                          errorMessage = "Error: Server side error. Please try again later.";
                        }

                        showErrorBanner(context, errorMessage);
                        throw Exception("Failed to load image: ${response.statusCode}");
                      }
                      JsonDecoder decoder = const JsonDecoder();
                      final Map<String, dynamic> jsonResponse = decoder.convert(response.body);
                      final String imageUrl = jsonResponse["url"];
                      print("Image URL: $imageUrl");
    
                      
                      response = await http.get(Uri.parse(imageUrl));
                      if (response.statusCode != 200) {
                        throw Exception("Failed to load image: ${response.statusCode}");
                      }
                      showSuccessBanner(context, "Image successfully fetched!");
                      final img.Image? decoded = img.decodeImage(response.bodyBytes);
                      if (decoded == null) {
                        throw Exception("Failed to decode image");
                      }
                      final img.Image resized = img.copyResize(decoded, width: 200, height: 200, maintainAspect: true);
                      BluetoothManager().setPayload(resized.getBytes());
                    }
                  },
                  child: const Text("Submit"),
                )
              ]
            )
          ),
        ),
      ),
    );
  }
}


Future<XFile> getImageXFileByUrl(String url) async {
  final file = XFile(url);
  return file;
}