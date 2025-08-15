import 'dart:io';
import 'package:flutter/material.dart';
import '../../../services/image_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/auth_helpers.dart';

class ProfileProvider with ChangeNotifier {
  final ImageService _imageService = ImageService();
  final StorageService _storageService = StorageService();
  
  File? _selectedImage;
  bool _isUploading = false;
  String? _uploadedImageUrl;
  String? _errorMessage;

  // Getters
  File? get selectedImage => _selectedImage;
  bool get isUploading => _isUploading;
  String? get uploadedImageUrl => _uploadedImageUrl;
  String? get errorMessage => _errorMessage;
  bool get hasSelectedImage => _selectedImage != null;

  // Select image from gallery
  Future<void> selectImageFromGallery() async {
    try {
      _clearError();
      final image = await _imageService.pickImageFromGallery();
      if (image != null) {
        await _validateAndSetImage(image);
      }
    } catch (e) {
      _setError('Failed to select image from gallery: $e');
    }
  }

  // Select image from camera
  Future<void> selectImageFromCamera() async {
    try {
      _clearError();
      final image = await _imageService.pickImageFromCamera();
      if (image != null) {
        await _validateAndSetImage(image);
      }
    } catch (e) {
      _setError('Failed to capture image: $e');
    }
  }

  // Upload profile image
  Future<String?> uploadProfileImage(String userId) async {
    if (_selectedImage == null) {
      _setError('No image selected');
      return null;
    }

    try {
      _setUploading(true);
      _clearError();

      final imageUrl = await _storageService.uploadProfileImage(_selectedImage!, userId);
      _uploadedImageUrl = imageUrl;
      
      if (imageUrl != null) {
        AuthHelpers.showSuccessToast('Profile image uploaded successfully');
      } else {
        _setError('Failed to upload image to storage');
      }
      return imageUrl;
    } catch (e) {
      final errorMessage = 'Failed to upload profile image: $e';
      _setError(errorMessage);
      return null;
    } finally {
      _setUploading(false);
    }
  }

  // Update user profile with image and display name
  Future<String?> updateUserProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? phoneNumber,
    String? oldPhotoURL,
  }) async {
    try {
      _setUploading(true);
      _clearError();

      String? newPhotoURL;
      
      // Upload new image if selected
      if (_selectedImage != null) {
        newPhotoURL = await uploadProfileImage(userId);
        if (newPhotoURL == null) {
          return null;
        }
      }

      // Note: Old image deletion should be handled by the calling code
      // after successful profile update to avoid premature deletion

      // Clear selected image after successful upload
      if (newPhotoURL != null) {
        clearSelectedImage();
      }

      return newPhotoURL;
    } catch (e) {
      final errorMessage = 'Failed to update user profile: $e';
      _setError(errorMessage);
      return null;
    } finally {
      _setUploading(false);
    }
  }

  // Delete profile image
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      _clearError();
      print('DEBUG: Attempting to delete image: $imageUrl');
      final success = await _storageService.deleteImage(imageUrl);
      if (success) {
        print('DEBUG: Image deleted successfully: $imageUrl');
        _uploadedImageUrl = null;
        AuthHelpers.showSuccessToast('Profile image deleted successfully');
      } else {
        print('DEBUG: Failed to delete image: $imageUrl');
        _setError('Failed to delete profile image');
      }
    } catch (e) {
      print('DEBUG: Error deleting image: $e');
      _setError('Failed to delete profile image: $e');
    }
  }

  // Clear selected image
  void clearSelectedImage() {
    _selectedImage = null;
    notifyListeners();
  }

  // Clear uploaded image URL
  void clearUploadedImageUrl() {
    _uploadedImageUrl = null;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _clearError();
  }

  // Validate and set image
  Future<void> _validateAndSetImage(File image) async {
    if (!_imageService.isValidImage(image)) {
      _setError('Invalid image file. Please select a valid image.');
      return;
    }

    _selectedImage = image;
    notifyListeners();
  }

  // Helper methods
  void _setUploading(bool uploading) {
    _isUploading = uploading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
} 