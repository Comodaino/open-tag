
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'dart:typed_data';
import '../theme/app_theme.dart';

class CropScreen extends StatelessWidget {
  final Uint8List imageBytes;
  CropScreen({Key? key, required this.imageBytes}) : super(key: key);

  final _cropController = CropController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Crop Image'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // This triggers the onCropped callback below
              _cropController.crop(); 
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Crop(
          image: imageBytes,
          controller: _cropController,
          onCropped: (result) {
            switch (result) {
                case CropSuccess(:final croppedImage):
                  Navigator.of(context).pop(croppedImage);
                case CropFailure():
                  Navigator.of(context).pop(null);
            }
          },
          aspectRatio: 1 / 1,     // Forces 1:1 square crop
          baseColor: Colors.black,
          maskColor: Colors.black.withOpacity(0.6),
          cornerDotBuilder: (size, edgeAlignment) => const DotControl(),
        ),
      ),
    );
  }
}