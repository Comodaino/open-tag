import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:open_tag_app/utils/bt_utils.dart';
import 'package:open_tag_app/screens/crop_screen.dart';

import '../theme/app_theme.dart';

/// Deep-purple image placeholder. Tapping it opens a sheet letting the
/// user take a photo or pick one from the gallery. Once an image is
/// selected it replaces the placeholder color with the picked image.
class ImagePlaceholder extends StatefulWidget {
  static const ImagePlaceholder _instance = ImagePlaceholder._internal();
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ImagePlaceholder._internal() : width = null, height = null, borderRadius = null;

  factory ImagePlaceholder() {
    return _instance;
  }

  @override
  State<ImagePlaceholder> createState() => _ImagePlaceholderState();
}

class _ImagePlaceholderState extends State<ImagePlaceholder> {
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;

  // Bytes of whatever we're currently showing (locally picked image,
  // already resized/encoded). This is what Image.memory renders — no
  // File/network path fragility across platforms.
  Uint8List? _previewBytes;

  final List<List<num>> _palette = [
    [0, 0, 0],       // Black
    [255, 255, 255], // White
    [255, 0, 0],     // Red
    [255, 255, 0],   // Yellow
  ];

  @override
  void initState() {
    super.initState();
    BluetoothManager().addListener(_onBluetoothChanged);
  }

  @override
  void dispose() {
    BluetoothManager().removeListener(_onBluetoothChanged);
    super.dispose();
  }

  void _onBluetoothChanged() {
    // Only fall back to whatever the Bluetooth payload holds if the user
    // hasn't picked a local image. A local pick always wins so it doesn't
    // get clobbered by the outgoing payload we just sent.
    if (_previewBytes == null) {
      setState(() {});
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _loading = true);
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );
      if (file == null) {
        setState(() => _loading = false);
        return;
      }

      final Uint8List bytes = await file.readAsBytes();
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw Exception('Unsupported image format');
      }

      final Uint8List rawBytes = await file.readAsBytes();

      if (!mounted) return;

      final Uint8List? croppedBytes = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CropScreen(imageBytes: rawBytes),
        ),
      );

      final img.Image resized;
      if (croppedBytes != null) {
        resized = img.copyResize(img.decodeImage(croppedBytes)!, width: 200, height: 200);
      } else {
        resized = img.copyResize(decoded, width: 200, height: 200);
      }

      _applyFloydSteinbergDithering(resized);

      // Encoded (PNG) bytes for on-screen preview.
      final Uint8List previewBytes = resized.getBytes(order: img.ChannelOrder.rgb);
      print("wow ${previewBytes.length}");
      // Raw pixel payload for the Bluetooth tag device.
      BluetoothManager().setPayload(previewBytes);


      if (!mounted) return;
      setState(() {
        _previewBytes = previewBytes;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get image: $e')),
        );
      }
    }
  }

  void _applyFloydSteinbergDithering(img.Image image) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);

        final oldR = pixel.r;
        final oldG = pixel.g;
        final oldB = pixel.b;

        // Find closest color in the palette
        final nearest = _getNearestColor(oldR, oldG, oldB);
        final newR = nearest[0];
        final newG = nearest[1];
        final newB = nearest[2];

        // Set the pixel to the palette color
        pixel.setRgb(newR, newG, newB);

        // Calculate the color error
        final errR = oldR - newR;
        final errG = oldG - newG;
        final errB = oldB - newB;

        // Distribute the error to surrounding pixels (Floyd-Steinberg diffusion matrix)
        _distributeError(image, x + 1, y, errR, errG, errB, 7 / 16);
        _distributeError(image, x - 1, y + 1, errR, errG, errB, 3 / 16);
        _distributeError(image, x, y + 1, errR, errG, errB, 5 / 16);
        _distributeError(image, x + 1, y + 1, errR, errG, errB, 1 / 16);
      }
    }
  }

  List<num> _getNearestColor(num r, num g, num b) {
    List<num> nearest = _palette.first;
    num minDistance = double.infinity;

    for (final color in _palette) {
      final distance = pow(r - color[0], 2) + pow(g - color[1], 2) + pow(b - color[2], 2);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = color;
      }
    }
    return nearest;
  }

  void _distributeError(img.Image imgData, int x, int y, num errR, num errG, num errB, double factor) {
    if (x >= 0 && x < imgData.width && y >= 0 && y < imgData.height) {
      final p = imgData.getPixel(x, y);
      p.setRgb(
        (p.r + errR * factor).clamp(0, 255),
        (p.g + errG * factor).clamp(0, 255),
        (p.b + errB * factor).clamp(0, 255),
      );
    }
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              if (!kIsWeb)
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_previewBytes != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove image'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _previewBytes = null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(32);

    // Local pick takes priority; otherwise fall back to whatever's on
    // the Bluetooth payload (assumed to already be encoded image bytes).
    print("Preview bytes length: ${_previewBytes?.length ?? 0}");
    print("Bluetooth payload length: ${BluetoothManager().getPayload?.length ?? 0}");
    //print(BluetoothManager().getPayload());
    final Uint8List? displayBytes =  _previewBytes;

    return GestureDetector(
      onTap: _loading ? null : _showSourceSheet,
      child: Container(
        width: widget.width,
        height: widget.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppTheme.brandPurple,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.brandPurple, AppTheme.brandPurpleDark],
          ),
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : displayBytes != null
                ? Image.memory(
                  Uint8List.fromList(img.encodePng(
                      img.Image.fromBytes(
                        width: 200,
                        height: 200,
                        bytes: displayBytes.buffer,
                        numChannels: 3,
                      )
                  )),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print(error);
                    return const Center(
                        child: Icon(Icons.broken_image_outlined, color: Colors.white70, size: 40),
                      );
                  }
                )
                : const Center(
                    child: Icon(Icons.add_a_photo_outlined, color: Colors.white70, size: 40),
                  ),
      ),
    );
  }
}