import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/authentication_models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create user document
  Future<void> createUser(UserModel user) async {
    try {
      print('DEBUG: FirestoreService.createUser called for uid: ${user.uid}');
      print('DEBUG: User data to save:');
      print('DEBUG: - email: ${user.email}');
      print('DEBUG: - displayName: ${user.displayName}');
      print('DEBUG: - photoURL: ${user.photoURL}');
      print('DEBUG: - phoneNumber: ${user.phoneNumber}');
      print('DEBUG: - bio: ${user.bio}');
      
      final userData = user.toMap();
      print('DEBUG: Converted to map: $userData');
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userData);
      
      print('DEBUG: User document saved successfully in Firestore');
    } catch (e) {
      print('DEBUG: Error creating user document: $e');
      rethrow;
    }
  }

  // Get user by ID
  Future<UserModel?> getUser(String uid) async {
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

  // Update user document
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .update(data);
  }

  // Delete user document
  Future<void> deleteUser(String uid) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .delete();
  }

  // Update last login time
  Future<void> updateLastLogin(String uid) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .update({
      'lastLoginAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Check if user exists
  Future<bool> userExists(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  // Get user stream for real-time updates
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // ========================================
  // FCM TOKEN MANAGEMENT
  // ========================================

  // Update user's FCM token
  Future<bool> updateFCMToken(String uid, String? token) async {
    try {
      print('DEBUG: Attempting to update FCM token for user: $uid');
      await _firestore
          .collection('users')
          .doc(uid)
          .update({
        'fcmToken': token,
      });
      print('DEBUG: FCM token updated successfully for user: $uid');
      return true;
    } catch (e) {
      print('DEBUG: Failed to update FCM token for user $uid: $e');
      return false;
    }
  }

  // Get user's FCM token
  Future<String?> getFCMToken(String uid) async {
    try {
      final user = await getUser(uid);
      return user?.fcmToken;
    } catch (e) {
      return null;
    }
  }

  // Get all users with valid FCM tokens
  Future<List<String>> getUsersWithFCMTokens() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('fcmToken', isNotEqualTo: null)
          .get();
      
      return querySnapshot.docs
          .map((doc) => doc.data()['fcmToken'] as String)
          .where((token) => token.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ========================================
  // NOTIFICATION PREFERENCES MANAGEMENT
  // ========================================

  // Update user's notification preferences
  Future<bool> updateNotificationPreferences(String uid, Map<String, bool> preferences) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({
        'notificationPreferences': preferences,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update specific notification preference
  Future<bool> updateNotificationPreference(String uid, String key, bool value) async {
    try {
      final user = await getUser(uid);
      if (user == null) return false;

      final updatedPreferences = Map<String, bool>.from(user.notificationPreferences);
      updatedPreferences[key] = value;

      await _firestore
          .collection('users')
          .doc(uid)
          .update({
        'notificationPreferences': updatedPreferences,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get user's notification preferences
  Future<Map<String, bool>?> getNotificationPreferences(String uid) async {
    try {
      final user = await getUser(uid);
      return user?.notificationPreferences;
    } catch (e) {
      return null;
    }
  }

  // Check if user has enabled specific notification type
  Future<bool> isNotificationEnabled(String uid, String type) async {
    try {
      final preferences = await getNotificationPreferences(uid);
      return preferences?[type] ?? true;
    } catch (e) {
      return true; // Default to enabled if error
    }
  }

  // Get users who have enabled specific notification type
  Future<List<String>> getUsersWithNotificationEnabled(String type) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('notificationPreferences.$type', isEqualTo: true)
          .get();
      
      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  // ========================================
  // BLOCK USER FUNCTIONALITY
  // ========================================

  // Block a user
  Future<bool> blockUser(String currentUserId, String userToBlockId) async {
    try {
      final currentUser = await getUser(currentUserId);
      if (currentUser == null) return false;

      final updatedUser = currentUser.blockUser(userToBlockId);
      await updateUser(currentUserId, {'blockedUsers': updatedUser.blockedUsers});
      return true;
    } catch (e) {
      return false;
    }
  }

  // Unblock a user
  Future<bool> unblockUser(String currentUserId, String userToUnblockId) async {
    try {
      final currentUser = await getUser(currentUserId);
      if (currentUser == null) return false;

      final updatedUser = currentUser.unblockUser(userToUnblockId);
      await updateUser(currentUserId, {'blockedUsers': updatedUser.blockedUsers});
      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if user1 has blocked user2
  Future<bool> isUserBlocked(String user1Id, String user2Id) async {
    try {
      final user1 = await getUser(user1Id);
      return user1?.hasBlockedUser(user2Id) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Check if two users have blocked each other (bidirectional check)
  Future<bool> areUsersBlocked(String user1Id, String user2Id) async {
    try {
      final user1Blocked = await isUserBlocked(user1Id, user2Id);
      final user2Blocked = await isUserBlocked(user2Id, user1Id);
      return user1Blocked || user2Blocked;
    } catch (e) {
      return false;
    }
  }

  // Get list of users that the current user has blocked
  Future<List<String>> getBlockedUsers(String currentUserId) async {
    try {
      final user = await getUser(currentUserId);
      return user?.blockedUsers ?? [];
    } catch (e) {
      return [];
    }
  }

  // Get list of users who have blocked the current user
  Future<List<String>> getUsersWhoBlockedMe(String currentUserId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('blockedUsers', arrayContains: currentUserId)
          .get();
      
      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }
} 