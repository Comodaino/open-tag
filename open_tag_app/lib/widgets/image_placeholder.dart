import 'dart:io';
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
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<ImagePlaceholder> createState() => _ImagePlaceholderState();
}

class _ImagePlaceholderState extends State<ImagePlaceholder> {
  XFile? _picked;
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _loading = true);
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file != null) {
        img.Image image = img.decodeImage(await file.readAsBytes())!;
        img.Image resizedImage = img.copyResize(image, width: 200, height: 200);
        BluetoothManager().setPayload(resizedImage.getBytes());
        setState(() => _picked = file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
              // Camera capture isn't available on web/desktop through
              // image_picker in the same way, but we still expose the
              // option — plug in file_picker/desktop camera APIs later
              // if you need native desktop capture.
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
              if (_picked != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove image'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _picked = null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage() {
    if (kIsWeb) {
      return Image.network(_picked!.path, fit: BoxFit.cover);
    }
    return Image.file(File(_picked!.path), fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(4);

    return GestureDetector(
      onTap: _loading ? null : _showSourceSheet,
      child: Container(
        width: widget.width,
        height: widget.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _picked == null ? AppTheme.brandPurple : null,
          gradient: _picked == null
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.brandPurple, AppTheme.brandPurpleDark],
                )
              : null,
          borderRadius: radius,
          border: Border.all(color: Colors.black87, width: 1.5),
        ),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _picked == null
                ? const Center(
                    child: Icon(
                      Icons.add_a_photo_outlined,
                      color: Colors.white70,
                      size: 40,
                    ),
                  )
                : _buildImage(),
      ),
    );
  }
}
