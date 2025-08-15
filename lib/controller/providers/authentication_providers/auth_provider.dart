import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../model/authentication_models/user_model.dart';
import '../../../model/authentication_models/auth_result.dart';
import '../../../services/firebase_auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/credentials_storage_service.dart';
import '../../../utils/auth_helpers.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();
  
  UserModel? _userData;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get userData => _userData;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _authService.currentUser;

  // Initialize authentication state
  Future<void> initialize() async {
    try {
      _setLoading(true);
      
      // Check current authentication state immediately
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await _loadUserData(currentUser.uid);
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
        _userData = null;
      }
      
      // Set up listener for future auth state changes
      _authService.authStateChanges.listen((User? user) async {
        if (user != null) {
          await _loadUserData(user.uid);
          _isAuthenticated = true;
        } else {
          _isAuthenticated = false;
          _userData = null;
        }
        notifyListeners();
      });
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with email and password
  Future<AuthResult> loginWithEmailAndPassword(String email, String password, {bool rememberMe = false}) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.signInWithEmailAndPassword(email, password);
      
      if (result.success) {
        // Load complete user data from Firestore instead of using the basic user model
        await _loadUserData(result.user!.uid);
        _isAuthenticated = true;
        
        // Save credentials if remember me is enabled
        if (rememberMe) {
          await CredentialsStorageService.saveCredentials(
            email: email,
            password: password,
            rememberMe: rememberMe,
          );
        }
        
        AuthHelpers.showSuccessToast(result.message ?? 'Successfully signed in');
      } else {
        _setError(result.message ?? 'Sign in failed');
        AuthHelpers.showErrorToast(result.message ?? 'Sign in failed');
      }

      return result;
    } catch (e) {
      final errorMessage = 'Login failed: $e';
      _setError(errorMessage);
      AuthHelpers.showErrorToast(errorMessage);
      return AuthResult.failure(message: errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // Register with email and password
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    String? photoURL,
    String? phoneNumber,
    String? bio,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        photoURL: photoURL,
        phoneNumber: phoneNumber,
        bio: bio,
      );
      
      if (result.success) {
        // Load complete user data from Firestore instead of using the basic user model
        await _loadUserData(result.user!.uid);
        _isAuthenticated = true;
        AuthHelpers.showSuccessToast(result.message ?? 'Account created successfully');
      } else {
        _setError(result.message ?? 'Registration failed');
      }

      return result;
    } catch (e) {
      final errorMessage = 'Registration failed: $e';
      _setError(errorMessage);
      return AuthResult.failure(message: errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<AuthResult> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.sendPasswordResetEmail(email);
      
      if (result.success) {
        AuthHelpers.showSuccessToast(result.message ?? 'Password reset email sent');
      } else {
        _setError(result.message ?? 'Failed to send reset email');
      }

      return result;
    } catch (e) {
      final errorMessage = 'Password reset failed: $e';
      _setError(errorMessage);
      return AuthResult.failure(message: errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // Change password
  Future<AuthResult> changePassword(String currentPassword, String newPassword) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.updatePassword(currentPassword, newPassword);
      
      if (result.success) {
        AuthHelpers.showSuccessToast(result.message ?? 'Password changed successfully');
      } else {
        _setError(result.message ?? 'Failed to change password');
      }

      return result;
    } catch (e) {
      final errorMessage = 'Password change failed: $e';
      _setError(errorMessage);
      return AuthResult.failure(message: errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // Update profile
  Future<AuthResult> updateProfile({
    String? displayName,
    String? photoURL,
    String? bio,
    String? phoneNumber,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
        bio: bio,
        phoneNumber: phoneNumber,
      );
      
      if (result.success) {
        await refreshUserData();
        AuthHelpers.showSuccessToast(result.message ?? 'Profile updated successfully');
      } else {
        _setError(result.message ?? 'Failed to update profile');
      }

      return result;
    } catch (e) {
      final errorMessage = 'Profile update failed: $e';
      _setError(errorMessage);
      return AuthResult.failure(message: errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<AuthResult> signOut() async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.signOut();
      
      if (result.success) {
        _isAuthenticated = false;
        _userData = null;
        
        // Clear chat provider data to prevent showing wrong user names
        // This will be handled by the main app when auth state changes
        AuthHelpers.showSuccessToast(result.message ?? 'Signed out successfully');
      } else {
        _setError(result.message ?? 'Sign out failed');
      }

      return result;
    } catch (e) {
      final errorMessage = 'Sign out failed: $e';
      _setError(errorMessage);
      return AuthResult.failure(message: errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // Delete account
  Future<AuthResult> deleteAccount(String password) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.deleteAccount(password);
      
      if (result.success) {
        _isAuthenticated = false;
        _userData = null;
        AuthHelpers.showSuccessToast(result.message ?? 'Account deleted successfully');
      } else {
        _setError(result.message ?? 'Failed to delete account');
      }

      return result;
    } catch (e) {
      final errorMessage = 'Account deletion failed: $e';
      _setError(errorMessage);
      return AuthResult.failure(message: errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _loadUserData(user.uid);
      }
    } catch (e) {
      _setError('Failed to refresh user data: $e');
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      print('DEBUG: Loading user data for uid: $uid');
      final userData = await _firestoreService.getUser(uid);
      if (userData != null) {
        print('DEBUG: User data loaded successfully');
        print('DEBUG: - numberofReviewsAsPoster: ${userData.numberofReviewsAsPoster}');
        print('DEBUG: - numberofReviewsAsDoer: ${userData.numberofReviewsAsDoer}');
        print('DEBUG: - ratings: ${userData.ratings}');
        _userData = userData;
        notifyListeners();
      } else {
        print('DEBUG: User data is null for uid: $uid');
      }
    } catch (e) {
      print('Failed to load user data: $e');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
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

  // Clear error message
  void clearError() {
    _clearError();
  }

  // Get saved credentials
  Future<Map<String, dynamic>> getSavedCredentials() async {
    return await CredentialsStorageService.getSavedCredentials();
  }

  // Clear saved credentials
  Future<void> clearSavedCredentials() async {
    await CredentialsStorageService.clearSavedCredentials();
  }
} 