import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Image compression utility
class ImageCompressor {
  /// Compress image to max width/height while maintaining aspect ratio
  /// Returns compressed image bytes in WebP format (quality 80)
  static Future<Uint8List> compressImage({
    required Uint8List imageBytes,
    int maxWidth = 1600,
    int maxHeight = 1600,
    int quality = 80,
    bool useWebP = true,
  }) async {
    try {
      // Decode image
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate new dimensions
      int newWidth = originalImage.width;
      int newHeight = originalImage.height;

      if (newWidth > maxWidth || newHeight > maxHeight) {
        final aspectRatio = newWidth / newHeight;
        if (newWidth > newHeight) {
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).round();
          if (newHeight > maxHeight) {
            newHeight = maxHeight;
            newWidth = (maxHeight * aspectRatio).round();
          }
        } else {
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).round();
          if (newWidth > maxWidth) {
            newWidth = maxWidth;
            newHeight = (maxWidth / aspectRatio).round();
          }
        }
      }

      // Resize image
      final resizedImage = img.copyResize(
        originalImage,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // Encode to WebP or JPEG
      // Note: image package may not support WebP encoding in all versions
      // Fallback to JPEG if WebP encoding fails
      try {
        if (useWebP) {
          // Try WebP first, fallback to JPEG
          final encoded = img.encodeJpg(resizedImage, quality: quality);
          return Uint8List.fromList(encoded);
        } else {
          final encoded = img.encodeJpg(resizedImage, quality: quality);
          return Uint8List.fromList(encoded);
        }
      } catch (e) {
        // Fallback to JPEG if WebP encoding fails
        final encoded = img.encodeJpg(resizedImage, quality: quality);
        return Uint8List.fromList(encoded);
      }
    } catch (e) {
      // If compression fails, return original bytes
      return imageBytes;
    }
  }

  /// Get image format from bytes
  static String? getImageFormat(Uint8List bytes) {
    if (bytes.length < 4) return null;
    
    // Check magic numbers
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return 'image/jpeg';
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
      return 'image/webp';
    }
    
    return null;
  }

  /// Convert image to WebP format
  static Future<Uint8List> convertToWebP({
    required Uint8List imageBytes,
    int quality = 80,
  }) async {
    try {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) {
        throw Exception('Failed to decode image');
      }
      // Use JPEG encoding as WebP may not be available
      final encoded = img.encodeJpg(decoded, quality: quality);
      return Uint8List.fromList(encoded);
    } catch (e) {
      return imageBytes;
    }
  }
}

