import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload profile image
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      print('DEBUG: Starting profile image upload for user: $userId');
      
      // Compress and resize image
      final compressedImage = await _compressImage(imageFile);
      print('DEBUG: Image compressed successfully');
      
      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_${userId}_$timestamp.jpg';
      print('DEBUG: Generated filename: $fileName');
      
      // Create reference
      final ref = _storage.ref().child('profile_images/$fileName');
      print('DEBUG: Created storage reference');
      
      // Upload compressed image
      print('DEBUG: Starting upload task');
      final uploadTask = ref.putData(compressedImage);
      final snapshot = await uploadTask;
      print('DEBUG: Upload completed, getting download URL');
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('DEBUG: Got download URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('DEBUG: Error uploading profile image: $e');
      return null;
    }
  }

  // Upload task delivery image
  Future<String?> uploadTaskDeliveryImage(File imageFile, String taskId) async {
    try {
      // Compress and resize image
      final compressedImage = await _compressImage(imageFile);
      
      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'delivery_${taskId}_$timestamp.jpg';
      
      // Create reference
      final ref = _storage.ref().child('task_delivery_images/$fileName');
      
      // Upload compressed image
      final uploadTask = ref.putData(compressedImage);
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  // Upload image with custom path
  Future<String?> uploadImage(File imageFile, String path) async {
    try {
      // Compress and resize image
      final compressedImage = await _compressImage(imageFile);
      
      // Create reference
      final ref = _storage.ref().child(path);
      
      // Upload compressed image
      final uploadTask = ref.putData(compressedImage);
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  // Delete image
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Compress and resize image
  Future<Uint8List> _compressImage(File imageFile) async {
    try {
      // Read image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image to max dimensions
      final resizedImage = img.copyResize(
        image,
        width: 800,
        height: 800,
        interpolation: img.Interpolation.linear,
      );

      // Compress image
      final compressedBytes = img.encodeJpg(resizedImage, quality: 85);
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      rethrow;
    }
  }

  // Validate image file
  bool isValidImageFile(File file) {
    final validExtensions = ['jpg', 'jpeg', 'png', 'gif'];
    final extension = file.path.split('.').last.toLowerCase();
    return validExtensions.contains(extension);
  }

  // Get file size in MB
  double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  // Check if file size is within limits (5MB)
  bool isFileSizeValid(File file) {
    return getFileSizeInMB(file) <= 5.0;
  }

  // Generate unique filename
  String generateUniqueFileName(String originalName, String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalName.split('.').last;
    return '${userId}_$timestamp.$extension';
  }
} 