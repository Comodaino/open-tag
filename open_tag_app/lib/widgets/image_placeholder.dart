import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:open_tag_app/utils/bt_utils.dart';

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
        imageQuality: 85,
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

      final img.Image resized = img.copyResize(decoded, width: 200, height: 200);

      // Raw pixel payload for the Bluetooth tag device.
      BluetoothManager().setPayload(resized.getBytes());

      // Encoded (PNG) bytes for on-screen preview.
      final Uint8List previewBytes = Uint8List.fromList(img.encodePng(resized));

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
    final Uint8List? displayBytes = _previewBytes ?? BluetoothManager().getPayload;

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
                    img.encodePng(img.Image.fromBytes(
                        width: 200,
                        height: 200,
                        bytes: displayBytes.buffer,
                        numChannels: 3,
                      )),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image_outlined, color: Colors.white70, size: 40),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.add_a_photo_outlined, color: Colors.white70, size: 40),
                  ),
      ),
    );
  }
}