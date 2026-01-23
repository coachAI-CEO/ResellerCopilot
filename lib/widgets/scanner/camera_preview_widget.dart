import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

/// Widget displaying the camera preview or selected image
///
/// Shows either:
/// - The selected product image (after taking photo/selecting from gallery)
/// - A placeholder with camera icon (when no image selected)
class CameraPreviewWidget extends StatelessWidget {
  final File? selectedImage;
  final Uint8List? selectedImageBytes;
  final VoidCallback onTakePhoto;
  final bool isAnalyzing;

  const CameraPreviewWidget({
    Key? key,
    this.selectedImage,
    this.selectedImageBytes,
    required this.onTakePhoto,
    this.isAnalyzing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image Preview Container
        Container(
          height: ImageConstants.previewHeight,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(BorderRadii.lg),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: selectedImageBytes != null
              ? _buildImagePreview()
              : _buildPlaceholder(),
        ),
        SizedBox(height: Spacing.base),

        // Take Photo Button
        ElevatedButton.icon(
          onPressed: isAnalyzing ? null : onTakePhoto,
          icon: const Icon(Icons.camera_alt),
          label: Text(selectedImageBytes != null ? 'Retake Photo' : 'Take Photo'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: Spacing.base),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(BorderRadii.lg),
      child: kIsWeb
          ? Image.memory(
              selectedImageBytes!,
              fit: BoxFit.cover,
            )
          : Image.file(
              selectedImage!,
              fit: BoxFit.cover,
            ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt,
            size: IconSizes.xl,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: Spacing.base),
          Text(
            'No image selected',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: FontSizes.md,
            ),
          ),
        ],
      ),
    );
  }
}
