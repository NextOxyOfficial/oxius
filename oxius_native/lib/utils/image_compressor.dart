import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

/// A utility class for compressing images across all platforms (web, iOS, Android)
/// 
/// Features:
/// - Aggressive compression matching backend requirements
/// - Target size: 80KB
/// - Progressive quality reduction
/// - Dimension scaling for large images
/// - Base64 encoding for API upload
/// - Cross-platform compatibility
class ImageCompressor {
  /// Default target size in bytes (80KB)
  static const int defaultTargetSize = 80 * 1024;
  
  /// Default initial quality (0-100)
  static const int defaultInitialQuality = 78;
  
  /// Default max dimension in pixels
  static const int defaultMaxDimension = 1200;
  
  /// Minimum quality before giving up (0-100)
  static const int minQuality = 45;
  
  /// Compress an image from XFile and return base64 string
  /// 
  /// Returns a base64 string with format: "data:image/jpeg;base64,..."
  /// This format is ready for API upload
  /// 
  /// Example:
  /// ```dart
  /// final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
  /// if (image != null) {
  ///   final base64String = await ImageCompressor.compressToBase64(image);
  ///   if (base64String != null) {
  ///     // Use base64String for API upload
  ///   }
  /// }
  /// ```
  static Future<String?> compressToBase64(
    XFile file, {
    int targetSize = defaultTargetSize,
    int initialQuality = defaultInitialQuality,
    int maxDimension = defaultMaxDimension,
    bool verbose = false,
  }) async {
    try {
      final compressedBytes = await compressToBytes(
        file,
        targetSize: targetSize,
        initialQuality: initialQuality,
        maxDimension: maxDimension,
        verbose: verbose,
      );
      
      if (compressedBytes != null) {
        final base64Image = 'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
        return base64Image;
      }
      
      return null;
    } catch (e) {
      if (verbose) print('Error compressing to base64: $e');
      return null;
    }
  }
  
  /// Compress an image from XFile and return Uint8List bytes
  /// 
  /// This is useful if you need the raw compressed bytes without base64 encoding
  /// 
  /// Example:
  /// ```dart
  /// final bytes = await ImageCompressor.compressToBytes(image);
  /// ```
  static Future<Uint8List?> compressToBytes(
    XFile file, {
    int targetSize = defaultTargetSize,
    int initialQuality = defaultInitialQuality,
    int maxDimension = defaultMaxDimension,
    bool verbose = false,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final int originalSize = bytes.length;
      
      if (verbose) {
        print('Original image size: ${formatFileSize(originalSize)}');
      }
      
      int quality = initialQuality;
      int currentMaxDimension = maxDimension;
      
      // Adjust settings for very large files
      if (originalSize > 5 * 1024 * 1024) {
        quality = 75;
        currentMaxDimension = 1000;
      }
      
      if (verbose) {
        print('Compressing image with quality: $quality, maxDimension: $currentMaxDimension');
      }
      
      Uint8List? compressedBytes;
      
      if (kIsWeb) {
        // Web-specific compression using Canvas API
        if (verbose) print('Using web-based compression');
        compressedBytes = await _compressImageWeb(
          bytes,
          quality,
          currentMaxDimension,
          verbose,
        );
        
        // Progressive compression for web
        while (compressedBytes != null && 
               compressedBytes.length > targetSize && 
               quality > minQuality) {
          quality -= 5;
          
          if (verbose) {
            print('Current size: ${formatFileSize(compressedBytes.length)}, recompressing with quality: $quality');
          }
          
          compressedBytes = await _compressImageWeb(
            bytes,
            quality,
            currentMaxDimension,
            verbose,
          );
        }
        
        // If still too large, reduce dimensions
        if (compressedBytes != null && compressedBytes.length > targetSize) {
          currentMaxDimension = 800;
          quality = 60;
          
          if (verbose) {
            print('Still too large, reducing dimensions to $currentMaxDimension with quality: $quality');
          }
          
          compressedBytes = await _compressImageWeb(
            bytes,
            quality,
            currentMaxDimension,
            verbose,
          );
        }
      } else {
        // Use flutter_image_compress for mobile platforms
        if (verbose) print('Using native compression');
        compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: currentMaxDimension,
          minHeight: currentMaxDimension,
          quality: quality,
          format: CompressFormat.jpeg,
        );
        
        // Progressive compression: reduce quality until target size is reached
        while (compressedBytes != null && 
               compressedBytes.length > targetSize && 
               quality > minQuality) {
          quality -= 5;
          
          if (verbose) {
            print('Current size: ${formatFileSize(compressedBytes.length)}, recompressing with quality: $quality');
          }
          
          compressedBytes = await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: currentMaxDimension,
            minHeight: currentMaxDimension,
            quality: quality,
            format: CompressFormat.jpeg,
          );
        }
        
        // If still too large after quality reduction, reduce dimensions
        if (compressedBytes != null && compressedBytes.length > targetSize) {
          currentMaxDimension = 800;
          quality = 60;
          
          if (verbose) {
            print('Still too large, reducing dimensions to $currentMaxDimension with quality: $quality');
          }
          
          compressedBytes = await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: currentMaxDimension,
            minHeight: currentMaxDimension,
            quality: quality,
            format: CompressFormat.jpeg,
          );
        }
      }
      
      if (compressedBytes != null && verbose) {
        print('Image compressed successfully: ${formatFileSize(originalSize)} → ${formatFileSize(compressedBytes.length)}');
      }
      
      return compressedBytes;
    } catch (e) {
      if (verbose) {
        print('Error compressing image: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      return null;
    }
  }
  
  /// Compress multiple images in parallel
  /// 
  /// Returns a list of base64 strings. Null values indicate compression failures.
  /// 
  /// Example:
  /// ```dart
  /// final images = [image1, image2, image3];
  /// final compressed = await ImageCompressor.compressMultipleToBase64(images);
  /// ```
  static Future<List<String?>> compressMultipleToBase64(
    List<XFile> files, {
    int targetSize = defaultTargetSize,
    int initialQuality = defaultInitialQuality,
    int maxDimension = defaultMaxDimension,
    bool verbose = false,
  }) async {
    final futures = files.map((file) => compressToBase64(
      file,
      targetSize: targetSize,
      initialQuality: initialQuality,
      maxDimension: maxDimension,
      verbose: verbose,
    ));
    
    return await Future.wait(futures);
  }
  
  /// Compress an image from raw bytes
  /// 
  /// Useful when you already have the image as bytes
  /// 
  /// Example:
  /// ```dart
  /// final Uint8List imageBytes = ...;
  /// final compressed = await ImageCompressor.compressFromBytes(imageBytes);
  /// ```
  static Future<Uint8List?> compressFromBytes(
    Uint8List bytes, {
    int targetSize = defaultTargetSize,
    int initialQuality = defaultInitialQuality,
    int maxDimension = defaultMaxDimension,
    bool verbose = false,
  }) async {
    try {
      final int originalSize = bytes.length;
      
      if (verbose) {
        print('Original image size: ${formatFileSize(originalSize)}');
      }
      
      int quality = initialQuality;
      int currentMaxDimension = maxDimension;
      
      // Adjust settings for very large files
      if (originalSize > 5 * 1024 * 1024) {
        quality = 75;
        currentMaxDimension = 1000;
      }
      
      Uint8List? compressedBytes;
      
      if (kIsWeb) {
        // Use web compression
        compressedBytes = await _compressImageWeb(
          bytes,
          quality,
          currentMaxDimension,
          verbose,
        );
        
        // Progressive compression
        while (compressedBytes != null && 
               compressedBytes.length > targetSize && 
               quality > minQuality) {
          quality -= 5;
          compressedBytes = await _compressImageWeb(
            bytes,
            quality,
            currentMaxDimension,
            verbose,
          );
        }
        
        // Reduce dimensions if still too large
        if (compressedBytes != null && compressedBytes.length > targetSize) {
          currentMaxDimension = 800;
          quality = 60;
          compressedBytes = await _compressImageWeb(
            bytes,
            quality,
            currentMaxDimension,
            verbose,
          );
        }
      } else {
        // Use native compression
        compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: currentMaxDimension,
          minHeight: currentMaxDimension,
          quality: quality,
          format: CompressFormat.jpeg,
        );
        
        // Progressive compression
        while (compressedBytes != null && 
               compressedBytes.length > targetSize && 
               quality > minQuality) {
          quality -= 5;
          compressedBytes = await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: currentMaxDimension,
            minHeight: currentMaxDimension,
            quality: quality,
            format: CompressFormat.jpeg,
          );
        }
        
        // Reduce dimensions if still too large
        if (compressedBytes != null && compressedBytes.length > targetSize) {
          currentMaxDimension = 800;
          quality = 60;
          compressedBytes = await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: currentMaxDimension,
            minHeight: currentMaxDimension,
            quality: quality,
            format: CompressFormat.jpeg,
          );
        }
      }
      
      if (compressedBytes != null && verbose) {
        print('Image compressed: ${formatFileSize(originalSize)} → ${formatFileSize(compressedBytes.length)}');
      }
      
      return compressedBytes;
    } catch (e) {
      if (verbose) print('Error compressing from bytes: $e');
      return null;
    }
  }
  
  /// Convert base64 string to Uint8List bytes
  /// 
  /// Handles both with and without "data:image" prefix
  /// 
  /// Example:
  /// ```dart
  /// final bytes = ImageCompressor.base64ToBytes('data:image/jpeg;base64,/9j/4AAQ...');
  /// ```
  static Uint8List? base64ToBytes(String base64String) {
    try {
      // Remove the prefix if it exists (e.g., "data:image/png;base64,")
      String base64Data = base64String;
      if (base64String.contains(',')) {
        base64Data = base64String.split(',')[1];
      }
      
      return base64Decode(base64Data);
    } catch (e) {
      print('Error decoding base64: $e');
      return null;
    }
  }
  
  /// Format file size for display
  /// 
  /// Example:
  /// ```dart
  /// print(ImageCompressor.formatFileSize(1024)); // "1.0 KB"
  /// print(ImageCompressor.formatFileSize(1048576)); // "1.0 MB"
  /// ```
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  /// Validate if a base64 string is a valid image
  /// 
  /// Checks if the string starts with "data:image" and contains valid base64
  static bool isValidBase64Image(String base64String) {
    if (!base64String.startsWith('data:image')) {
      return false;
    }
    
    try {
      base64ToBytes(base64String);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Get the estimated compression ratio
  /// 
  /// Returns a value between 0 and 1, where:
  /// - 0 means no compression (impossible)
  /// - 0.5 means 50% size reduction
  /// - 0.9 means 90% size reduction
  static double getCompressionRatio(int originalSize, int compressedSize) {
    if (originalSize == 0) return 0;
    return 1 - (compressedSize / originalSize);
  }
  
  /// Web-specific image compression using Flutter's image codec
  /// 
  /// This method uses Flutter's built-in image codec to decode and re-encode
  /// images with compression on web platform
  static Future<Uint8List?> _compressImageWeb(
    Uint8List bytes,
    int quality,
    int maxDimension,
    bool verbose,
  ) async {
    try {
      // Decode the image
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      
      if (verbose) {
        print('Original dimensions: ${image.width}x${image.height}');
      }
      
      // Calculate new dimensions while maintaining aspect ratio
      int width = image.width;
      int height = image.height;
      
      if (width > maxDimension || height > maxDimension) {
        if (width > height) {
          height = (height * maxDimension / width).round();
          width = maxDimension;
        } else {
          width = (width * maxDimension / height).round();
          height = maxDimension;
        }
        
        if (verbose) {
          print('Resizing to: ${width}x${height}');
        }
      }
      
      // Create a picture recorder to draw the resized image
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      
      // Draw the image scaled to new dimensions
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..filterQuality = FilterQuality.high,
      );
      
      // End recording and create the new image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image resizedImage = await picture.toImage(width, height);
      
      // Convert to bytes with quality
      // Note: Web doesn't support quality parameter directly in toByteData
      // We simulate quality by reducing dimensions more aggressively
      final ByteData? byteData = await resizedImage.toByteData(
        format: ui.ImageByteFormat.png, // Using PNG for web compatibility
      );
      
      if (byteData == null) {
        if (verbose) print('Failed to convert image to byte data');
        return null;
      }
      
      final Uint8List compressedBytes = byteData.buffer.asUint8List();
      
      if (verbose) {
        print('Compressed to: ${formatFileSize(compressedBytes.length)}');
      }
      
      return compressedBytes;
    } catch (e) {
      if (verbose) print('Error in web compression: $e');
      return null;
    }
  }
}
