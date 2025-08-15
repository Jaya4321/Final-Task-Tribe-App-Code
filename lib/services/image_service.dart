import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'storage_service.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        
        // Validate image
        if (!_storageService.isValidImageFile(file)) {
          throw Exception('Invalid image format. Please select a valid image file.');
        }

        if (!_storageService.isFileSizeValid(file)) {
          throw Exception('Image file is too large. Please select an image smaller than 5MB.');
        }

        return file;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        
        // Validate image
        if (!_storageService.isValidImageFile(file)) {
          throw Exception('Invalid image format. Please select a valid image file.');
        }

        if (!_storageService.isFileSizeValid(file)) {
          throw Exception('Image file is too large. Please select an image smaller than 5MB.');
        }

        return file;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Validate image file
  bool isValidImage(File file) {
    return _storageService.isValidImageFile(file) && 
           _storageService.isFileSizeValid(file);
  }

  // Get file size in readable format
  String getFileSizeString(File file) {
    final sizeInMB = _storageService.getFileSizeInMB(file);
    if (sizeInMB < 1) {
      return '${(sizeInMB * 1024).toStringAsFixed(1)} KB';
    }
    return '${sizeInMB.toStringAsFixed(1)} MB';
  }
} 