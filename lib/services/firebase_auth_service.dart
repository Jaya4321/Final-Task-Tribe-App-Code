import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer' as developer;
import '../model/authentication_models/user_model.dart';
import '../model/authentication_models/auth_result.dart';
import 'firestore_service.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get and store FCM token for a user
  Future<String?> _getAndStoreFCMToken(String userId) async {
    try {
      final token = await _firebaseMessaging.getToken();
      developer.log('Generated FCM token for user $userId: ${token != null ? 'Success' : 'Failed'}');
      
      if (token != null) {
        developer.log('FCM token: ${token.substring(0, 20)}...');
        
        // Check if user document exists before updating FCM token
        final userExists = await _firestoreService.userExists(userId);
        if (userExists) {
          final success = await _firestoreService.updateFCMToken(userId, token);
          developer.log('FCM token storage for user $userId: ${success ? 'Success' : 'Failed'}');
        } else {
          developer.log('User document does not exist for FCM token update: $userId');
        }
        return token;
      }
      return null;
    } catch (e) {
      developer.log('Failed to get/store FCM token: $e');
      return null;
    }
  }

  // Listen for FCM token changes and update Firestore
  void _listenForTokenChanges(String userId) {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      try {
        await _firestoreService.updateFCMToken(userId, newToken);
        print('FCM token updated for user: $userId');
      } catch (e) {
        print('Failed to update FCM token: $e');
      }
    });
  }

  // Initialize FCM token for current user (call this when app starts)
  Future<void> initializeFCMTokenForCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _getAndStoreFCMToken(user.uid);
      _listenForTokenChanges(user.uid);
    }
  }

  // Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword(String email, String password) async {
    try {
      developer.log('DEBUG: Attempting to sign in with email-->: $email');
      developer.log('DEBUG: Attempting to sign in with password-->: $password');
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      developer.log('DEBUG: Sign in with email and password result-->: ${userCredential.user != null ? 'Success' : 'Failed'}');

      if (userCredential.user != null) {
        developer.log('DEBUG: Sign in with email and password successful-->');
        // Update last login time in Firestore
        await _updateLastLogin(userCredential.user!.uid);
        
        // Get and store FCM token
        await _getAndStoreFCMToken(userCredential.user!.uid);
        
        // Listen for FCM token changes
        _listenForTokenChanges(userCredential.user!.uid);
        
        return AuthResult.success(
          message: 'Successfully signed in',
          data: UserModel.fromFirebaseUser(userCredential.user!),
        );
      }
      developer.log('DEBUG: Sign in with email and password failed');

      return AuthResult.failure(message: 'Sign in failed');
    } on FirebaseAuthException catch (e) {
      developer.log('DEBUG: FirebaseAuthException-->: ${e.code} - ${e.message}');
      return _handleAuthException(e);
    } catch (e) {
      developer.log('DEBUG: Unexpected error-->: $e');
      return AuthResult.failure(message: 'An unexpected error occurred: $e');
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
      print('DEBUG: Starting registration with email: $email, displayName: $displayName');
      print('DEBUG: Additional data - photoURL: $photoURL, phoneNumber: $phoneNumber, bio: $bio');
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        print('DEBUG: Firebase Auth user created successfully: ${userCredential.user!.uid}');
        
        // Update display name in Firebase Auth
        await userCredential.user!.updateDisplayName(displayName);
        print('DEBUG: Display name updated in Firebase Auth: $displayName');
        
        // Get FCM token
        final fcmToken = await _firebaseMessaging.getToken();
        print('DEBUG: FCM token obtained: ${fcmToken != null ? 'Success' : 'Failed'}');
        
        // Create user document in Firestore with complete data structure
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          email: email.trim(),
          displayName: displayName,
          photoURL: photoURL,
          phoneNumber: phoneNumber,
          bio: bio,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          ratings: {'asPoster': 0.0, 'asDoer': 0.0},
          tasksPosted: [],
          tasksAccepted: [],
          fcmToken: fcmToken,
          notificationPreferences: {
            'task_notifications': true,
            'chat_notifications': true,
            'system_notifications': true,
            'mutual_task_notifications': true,
          },
        );

        print('DEBUG: Creating user document in Firestore with data:');
        print('DEBUG: - uid: ${userModel.uid}');
        print('DEBUG: - email: ${userModel.email}');
        print('DEBUG: - displayName: ${userModel.displayName}');
        print('DEBUG: - photoURL: ${userModel.photoURL}');
        print('DEBUG: - phoneNumber: ${userModel.phoneNumber}');
        print('DEBUG: - bio: ${userModel.bio}');
        
        // Create user document in Firestore
        await _firestoreService.createUser(userModel);
        print('DEBUG: User document created successfully in Firestore');

        // Initialize FCM token handling for the new user
        _listenForTokenChanges(userCredential.user!.uid);

        return AuthResult.success(
          message: 'Account created successfully',
          data: userModel,
        );
      }

      return AuthResult.failure(message: 'Registration failed');
    } on FirebaseAuthException catch (e) {
      print('DEBUG: Firebase Auth Exception during registration: ${e.code} - ${e.message}');
      return _handleAuthException(e);
    } catch (e) {
      print('DEBUG: Unexpected error during registration: $e');
      return AuthResult.failure(message: 'An unexpected error occurred: $e');
    }
  }

  // Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(
        message: 'Password reset email sent successfully',
      );
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      return AuthResult.failure(message: 'An unexpected error occurred: $e');
    }
  }

  // Update password
  Future<AuthResult> updatePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure(message: 'No user is currently signed in');
      }

      // Re-authenticate user before password change
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      return AuthResult.success(message: 'Password updated successfully');
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      return AuthResult.failure(message: 'An unexpected error occurred: $e');
    }
  }

  // Update user profile
  Future<AuthResult> updateProfile({
    String? displayName,
    String? photoURL,
    String? bio,
    String? phoneNumber,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure(message: 'No user is currently signed in');
      }

      print('DEBUG: Updating Firebase Auth profile - displayName: $displayName, photoURL: $photoURL');

      // Update Firebase Auth profile
      if (displayName != null) {
        print('DEBUG: Updating display name to: $displayName');
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        print('DEBUG: Updating photo URL to: $photoURL');
        await user.updatePhotoURL(photoURL);
      }

      // Update Firestore document
      final updateData = <String, dynamic>{};
      if (displayName != null) updateData['displayName'] = displayName;
      if (photoURL != null) updateData['photoURL'] = photoURL;
      if (bio != null) updateData['bio'] = bio;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;

      if (updateData.isNotEmpty) {
        print('DEBUG: Updating Firestore with data: $updateData');
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update(updateData);
        print('DEBUG: Firestore update completed');
      }

      print('DEBUG: Profile update successful');
      return AuthResult.success(message: 'Profile updated successfully');
    } on FirebaseAuthException catch (e) {
      print('DEBUG: Firebase Auth exception: ${e.code} - ${e.message}');
      return _handleAuthException(e);
    } catch (e) {
      print('DEBUG: Unexpected error in updateProfile: $e');
      return AuthResult.failure(message: 'An unexpected error occurred: $e');
    }
  }

  // Sign out
  Future<AuthResult> signOut() async {
    try {
      await _auth.signOut();
      return AuthResult.success(message: 'Signed out successfully');
    } catch (e) {
      return AuthResult.failure(message: 'Sign out failed: $e');
    }
  }

  // Delete account
  Future<AuthResult> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure(message: 'No user is currently signed in');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth account
      await user.delete();

      return AuthResult.success(message: 'Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      return _handleAuthException(e);
    } catch (e) {
      return AuthResult.failure(message: 'An unexpected error occurred: $e');
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update last login time
  Future<void> _updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Silently fail for last login update
    }
  }

  // Handle Firebase Auth exceptions
  AuthResult _handleAuthException(FirebaseAuthException e) {
    String message;
    
    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email address';
        break;
      case 'wrong-password':
        message = 'Incorrect password';
        break;
      case 'email-already-in-use':
        message = 'An account with this email already exists';
        break;
      case 'weak-password':
        message = 'Password is too weak. Please choose a stronger password';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email address';
        break;
      case 'user-disabled':
        message = 'This account has been disabled';
        break;
      case 'too-many-requests':
        message = 'Too many failed attempts. Please try again later';
        break;
      case 'operation-not-allowed':
        message = 'This operation is not allowed';
        break;
      case 'requires-recent-login':
        message = 'Please sign in again to perform this action';
        break;
      default:
        message = e.message ?? 'Authentication failed';
    }

    return AuthResult.failure(message: message, errorCode: e.code);
  }
} 