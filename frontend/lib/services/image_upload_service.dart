import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/services.dart';
import '../config/api_config.dart';

class ImageUploadService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery or camera
  static Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
    int maxWidth = 1920,
    int maxHeight = 1080,
    int quality = 80,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') {
        throw Exception('Camera access denied. Please enable camera permission in settings.');
      } else if (e.code == 'photo_access_denied') {
        throw Exception('Photo library access denied. Please enable photo library permission in settings.');
      } else if (e.code == 'no_available_camera') {
        throw Exception('No camera available on this device.');
      } else {
        throw Exception('Failed to pick image: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Upload image to backend
  static Future<String> uploadImage(File imageFile) async {
    try {
      // Determine content type
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      
      // Read file as bytes
      final bytes = await imageFile.readAsBytes();
      
      // Create multipart request
      final uri = Uri.parse('${ApiConfig.baseUrl}/upload/image');
      final request = http.MultipartRequest('POST', uri);
      
      // Add file to request
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: path.basename(imageFile.path),
        contentType: MediaType.parse(mimeType),
      );
      
      request.files.add(multipartFile);
      
      // Send request
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        // Parse response to get image URL
        // This will depend on your backend response format
        return responseBody; // Assuming backend returns the image URL directly
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  /// Pick and upload image in one step
  static Future<String?> pickAndUploadImage({
    ImageSource source = ImageSource.gallery,
    int maxWidth = 1920,
    int maxHeight = 1080,
    int quality = 80,
  }) async {
    try {
      final imageFile = await pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );
      
      if (imageFile != null) {
        return await uploadImage(imageFile);
      }
      return null;
    } catch (e) {
      throw Exception('Pick and upload failed: $e');
    }
  }
}