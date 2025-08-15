import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final String? bio;
  final Map<String, double> ratings;
  final List<String> tasksPosted;
  final List<String> tasksAccepted;
  final int numberofReviewsAsDoer;
  final int numberofReviewsAsPoster;
  final List<String> blockedUsers;
  final String? fcmToken;
  final Map<String, bool> notificationPreferences;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.phoneNumber,
    required this.createdAt,
    required this.lastLoginAt,
    this.bio,
    this.ratings = const {'asPoster': 0.0, 'asDoer': 0.0},
    this.tasksPosted = const [],
    this.tasksAccepted = const [],
    this.numberofReviewsAsDoer = 0,
    this.numberofReviewsAsPoster = 0,
    this.blockedUsers = const [],
    this.fcmToken,
    this.notificationPreferences = const {
      'task_notifications': true,
      'chat_notifications': true,
      'system_notifications': true,
      'mutual_task_notifications': true,
    },
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      phoneNumber: data['phoneNumber'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
      bio: data['bio'],
      ratings: Map<String, double>.from(data['ratings'] ?? {'asPoster': 0.0, 'asDoer': 0.0}),
      tasksPosted: List<String>.from(data['tasksPosted'] ?? []),
      tasksAccepted: List<String>.from(data['tasksAccepted'] ?? []),
      numberofReviewsAsDoer: data['numberofReviewsAsDoer'] ?? 0,
      numberofReviewsAsPoster: data['numberofReviewsAsPoster'] ?? 0,
      blockedUsers: List<String>.from(data['blockedUsers'] ?? []),
      fcmToken: data['fcmToken'],
      notificationPreferences: Map<String, bool>.from(data['notificationPreferences'] ?? {
        'task_notifications': true,
        'chat_notifications': true,
        'system_notifications': true,
        'mutual_task_notifications': true,
      }),
    );
  }

  factory UserModel.fromFirebaseUser(dynamic firebaseUser) {
    return UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      phoneNumber: firebaseUser.phoneNumber,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      bio: null,
      ratings: {'asPoster': 0.0, 'asDoer': 0.0},
      tasksPosted: [],
      tasksAccepted: [],
      numberofReviewsAsDoer: 0,
      numberofReviewsAsPoster: 0,
      blockedUsers: [],
      fcmToken: null, // Will be set later
      notificationPreferences: {
        'task_notifications': true,
        'chat_notifications': true,
        'system_notifications': true,
        'mutual_task_notifications': true,
      },
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'bio': bio,
      'ratings': ratings,
      'tasksPosted': tasksPosted,
      'tasksAccepted': tasksAccepted,
      'numberofReviewsAsDoer': numberofReviewsAsDoer,
      'numberofReviewsAsPoster': numberofReviewsAsPoster,
      'blockedUsers': blockedUsers,
      'fcmToken': fcmToken,
      'notificationPreferences': notificationPreferences,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? bio,
    Map<String, double>? ratings,
    List<String>? tasksPosted,
    List<String>? tasksAccepted,
    int? numberofReviewsAsDoer,
    int? numberofReviewsAsPoster,
    List<String>? blockedUsers,
    String? fcmToken,
    Map<String, bool>? notificationPreferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      bio: bio ?? this.bio,
      ratings: ratings ?? this.ratings,
      tasksPosted: tasksPosted ?? this.tasksPosted,
      tasksAccepted: tasksAccepted ?? this.tasksAccepted,
      numberofReviewsAsDoer: numberofReviewsAsDoer ?? this.numberofReviewsAsDoer,
      numberofReviewsAsPoster: numberofReviewsAsPoster ?? this.numberofReviewsAsPoster,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      fcmToken: fcmToken ?? this.fcmToken,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
    );
  }

  // Block user functionality
  bool hasBlockedUser(String userId) {
    return blockedUsers.contains(userId);
  }

  UserModel blockUser(String userId) {
    if (!hasBlockedUser(userId)) {
      final updatedBlockedUsers = List<String>.from(blockedUsers)..add(userId);
      return copyWith(blockedUsers: updatedBlockedUsers);
    }
    return this;
  }

  UserModel unblockUser(String userId) {
    if (hasBlockedUser(userId)) {
      final updatedBlockedUsers = List<String>.from(blockedUsers)..remove(userId);
      return copyWith(blockedUsers: updatedBlockedUsers);
    }
    return this;
  }

  // FCM Token management
  UserModel updateFCMToken(String? newToken) {
    return copyWith(fcmToken: newToken);
  }

  // Notification preferences management
  UserModel updateNotificationPreference(String key, bool value) {
    final updatedPreferences = Map<String, bool>.from(notificationPreferences);
    updatedPreferences[key] = value;
    return copyWith(notificationPreferences: updatedPreferences);
  }

  UserModel updateNotificationPreferences(Map<String, bool> preferences) {
    return copyWith(notificationPreferences: preferences);
  }

  bool isNotificationEnabled(String type) {
    return notificationPreferences[type] ?? true;
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
} 