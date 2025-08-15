import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_tribe_app/services/notification_service.dart';
import 'package:task_tribe_app/services/firestore_service.dart';

/// Helper class for sending notifications across different modules
class NotificationHelper {
  static final NotificationServices _notificationService = NotificationServices.instance;
  static final FirestoreService _firestoreService = FirestoreService();

  // ==================== TASK MODULE NOTIFICATIONS ====================

  /// Send notification when a task is assigned to someone
  static Future<void> notifyTaskAssignment({
    required String assigneeId,
    required String taskTitle,
    required String taskId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Check if user has task notifications enabled
    final isEnabled = await _firestoreService.isNotificationEnabled(assigneeId, 'task_notifications');
    if (!isEnabled) return;

    // Get assigner name
    final assignerDoc = await _firestoreService.getUser(currentUser.uid);
    final assignerName = assignerDoc?.displayName ?? 'Someone';

    await _notificationService.sendNotificationToUser(
      userId: assigneeId,
      title: "New Task Assigned",
      body: "$assignerName assigned you: $taskTitle",
      data: {
        'notification_type': 'task_assigned',
        'task_id': taskId,
        'assigner_name': assignerName,
        'task_title': taskTitle,
      },
      senderId: currentUser.uid,
    );
  }

  /// Send notification when someone accepts a task
  static Future<void> notifyTaskAcceptance({
    required String taskOwnerId,
    required String taskTitle,
    required String taskId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Check if user has task notifications enabled
    final isEnabled = await _firestoreService.isNotificationEnabled(taskOwnerId, 'task_notifications');
    if (!isEnabled) return;

    // Get acceptor name
    final acceptorDoc = await _firestoreService.getUser(currentUser.uid);
    final acceptorName = acceptorDoc?.displayName ?? 'Someone';

    await _notificationService.sendNotificationToUser(
      userId: taskOwnerId,
      title: "Task Accepted",
      body: "$acceptorName accepted your task: $taskTitle",
      data: {
        'notification_type': 'task_accepted',
        'task_id': taskId,
        'acceptor_name': acceptorName,
        'task_title': taskTitle,
      },
      senderId: currentUser.uid,
    );
  }

  /// Send notification when a task is delivered
  static Future<void> notifyTaskDelivery({
    required String taskOwnerId,
    required String taskTitle,
    required String taskId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Check if user has task notifications enabled
    final isEnabled = await _firestoreService.isNotificationEnabled(taskOwnerId, 'task_notifications');
    if (!isEnabled) return;

    // Get deliverer name
    final delivererDoc = await _firestoreService.getUser(currentUser.uid);
    final delivererName = delivererDoc?.displayName ?? 'Someone';

    await _notificationService.sendNotificationToUser(
      userId: taskOwnerId,
      title: "Task Delivered",
      body: "$delivererName delivered your task: $taskTitle",
      data: {
        'notification_type': 'task_delivered',
        'task_id': taskId,
        'deliverer_name': delivererName,
        'task_title': taskTitle,
      },
      senderId: currentUser.uid,
    );
  }

  /// Send notification when a task is reviewed
  static Future<void> notifyTaskReview({
    required String taskOwnerId,
    required String taskTitle,
    required String taskId,
    required double rating,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Check if user has task notifications enabled
    final isEnabled = await _firestoreService.isNotificationEnabled(taskOwnerId, 'task_notifications');
    if (!isEnabled) return;

    // Get reviewer name
    final reviewerDoc = await _firestoreService.getUser(currentUser.uid);
    final reviewerName = reviewerDoc?.displayName ?? 'Someone';

    await _notificationService.sendNotificationToUser(
      userId: taskOwnerId,
      title: "Task Reviewed",
      body: "$reviewerName reviewed your task: $taskTitle",
      data: {
        'notification_type': 'task_reviewed',
        'task_id': taskId,
        'reviewer_name': reviewerName,
        'task_title': taskTitle,
        'rating': rating,
      },
      senderId: currentUser.uid,
    );
  }

  /// Send notification when someone is hired for a task
  static Future<void> notifyTaskHiring({
    required String hiredUserId,
    required String taskTitle,
    required String taskId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Check if user has task notifications enabled
    final isEnabled = await _firestoreService.isNotificationEnabled(hiredUserId, 'task_notifications');
    if (!isEnabled) return;

    // Get task owner name
    final taskOwnerDoc = await _firestoreService.getUser(currentUser.uid);
    final taskOwnerName = taskOwnerDoc?.displayName ?? 'Someone';

    await _notificationService.sendNotificationToUser(
      userId: hiredUserId,
      title: "You've Been Hired!",
      body: "$taskOwnerName hired you for: $taskTitle",
      data: {
        'notification_type': 'task_hired',
        'task_id': taskId,
        'task_owner_name': taskOwnerName,
        'task_title': taskTitle,
      },
      senderId: currentUser.uid,
    );
  }

  /// Send notification to users who were not hired for a task
  static Future<void> notifyTaskNotHired({
    required List<String> notHiredUserIds,
    required String taskTitle,
    required String taskId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Filter users who have task notifications enabled
    final enabledUserIds = <String>[];
    for (final userId in notHiredUserIds) {
      final isEnabled = await _firestoreService.isNotificationEnabled(userId, 'task_notifications');
      if (isEnabled) {
        enabledUserIds.add(userId);
      }
    }

    if (enabledUserIds.isEmpty) return;

    // Get task owner name
    final taskOwnerDoc = await _firestoreService.getUser(currentUser.uid);
    final taskOwnerName = taskOwnerDoc?.displayName ?? 'Someone';

    await _notificationService.sendNotificationToMultipleUsers(
      userIds: enabledUserIds,
      title: "Application Update",
      body: "$taskOwnerName hired someone else for: $taskTitle",
      data: {
        'notification_type': 'task_not_hired',
        'task_id': taskId,
        'task_owner_name': taskOwnerName,
        'task_title': taskTitle,
      },
      senderId: currentUser.uid,
    );
  }

  /// Send notification when someone applies for a task
  static Future<void> notifyTaskApplication({
    required String taskOwnerId,
    required String taskTitle,
    required String taskId,
    required String applicantId,
  }) async {
    // Check if user has task notifications enabled
    final isEnabled = await _firestoreService.isNotificationEnabled(taskOwnerId, 'task_notifications');
    if (!isEnabled) return;

    // Get applicant name
    final applicantDoc = await _firestoreService.getUser(applicantId);
    final applicantName = applicantDoc?.displayName ?? 'Someone';

    await _notificationService.sendNotificationToUser(
      userId: taskOwnerId,
      title: "New Task Application",
      body: "$applicantName applied for your task: $taskTitle",
      data: {
        'notification_type': 'task_application',
        'task_id': taskId,
        'applicant_id': applicantId,
        'applicant_name': applicantName,
        'task_title': taskTitle,
      },
      senderId: applicantId,
    );
  }

  /// Send notification when delivery is accepted
  static Future<void> notifyDeliveryAccepted({
    required String doerId,
    required String taskTitle,
    required String taskId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Check if user has task notifications enabled
    final isEnabled = await _firestoreService.isNotificationEnabled(doerId, 'task_notifications');
    if (!isEnabled) return;

    // Get poster name
    final posterDoc = await _firestoreService.getUser(currentUser.uid);
    final posterName = posterDoc?.displayName ?? 'Someone';

    await _notificationService.sendNotificationToUser(
      userId: doerId,
      title: "Delivery Accepted!",
      body: "$posterName accepted your delivery for: $taskTitle",
      data: {
        'notification_type': 'delivery_accepted',
        'task_id': taskId,
        'poster_name': posterName,
        'task_title': taskTitle,
      },
      senderId: currentUser.uid,
    );
  }

  /// Send notification when delivery is rejected
  static Future<void> notifyDeliveryRejected({
    required String doerId,
    required String taskTitle,
    required String taskId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Check if user has task notifications enabled
    final isEnabled = await _firestoreService.isNotificationEnabled(doerId, 'task_notifications');
    if (!isEnabled) return;

    // Get poster name
    final posterDoc = await _firestoreService.getUser(currentUser.uid);
    final posterName = posterDoc?.displayName ?? 'Someone';

    await _notificationService.sendNotificationToUser(
      userId: doerId,
      title: "Delivery Rejected",
      body: "$posterName rejected your delivery for: $taskTitle. Please check and resubmit.",
      data: {
        'notification_type': 'delivery_rejected',
        'task_id': taskId,
        'poster_name': posterName,
        'task_title': taskTitle,
      },
      senderId: currentUser.uid,
    );
  }



  // ==================== MUTUAL TASK MODULE NOTIFICATIONS ====================

  /// Send notification when a mutual task proposal is accepted
  static Future<void> notifyMutualTaskProposalAccepted({
    required String proposerId,
    required String taskTitle,
    required String taskId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Check if user has mutual task notifications enabled
    final isEnabled = await _firestoreService.isNotificationEnabled(proposerId, 'mutual_task_notifications');
    if (!isEnabled) return;

    // Get task owner name
    final taskOwnerDoc = await _firestoreService.getUser(currentUser.uid);
    final taskOwnerName = taskOwnerDoc?.displayName ?? 'Someone';

    await _notificationService.sendNotificationToUser(
      userId: proposerId,
      title: "Proposal Accepted!",
      body: "$taskOwnerName accepted your proposal for: $taskTitle",
      data: {
        'notification_type': 'mutual_task_proposal_accepted',
        'task_id': taskId,
        'task_owner_name': taskOwnerName,
        'task_title': taskTitle,
      },
      senderId: currentUser.uid,
    );
  }

  /// Send notification when a mutual task proposal is rejected
  static Future<void> notifyMutualTaskProposalRejected({
    required String proposerId,
    required String taskTitle,
    required String taskId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Check if user has mutual task notifications enabled
    final isEnabled = await _firestoreService.isNotificationEnabled(proposerId, 'mutual_task_notifications');
    if (!isEnabled) return;

    // Get task owner name
    final taskOwnerDoc = await _firestoreService.getUser(currentUser.uid);
    final taskOwnerName = taskOwnerDoc?.displayName ?? 'Someone';

    await _notificationService.sendNotificationToUser(
      userId: proposerId,
      title: "Proposal Update",
      body: "$taskOwnerName rejected your proposal for: $taskTitle",
      data: {
        'notification_type': 'mutual_task_proposal_rejected',
        'task_id': taskId,
        'task_owner_name': taskOwnerName,
        'task_title': taskTitle,
      },
      senderId: currentUser.uid,
    );
  }

  /// Send notification when a mutual task proposal is received
  static Future<void> notifyMutualTaskProposalReceived({
    required String taskOwnerId,
    required String taskTitle,
    required String proposerId,
    required String taskId,
  }) async {
    // Check if user has mutual task notifications enabled
    final isEnabled = await _firestoreService.isNotificationEnabled(taskOwnerId, 'mutual_task_notifications');
    if (!isEnabled) return;

    // Get proposer name
    final proposerDoc = await _firestoreService.getUser(proposerId);
    final proposerName = proposerDoc?.displayName ?? 'Someone';

    await _notificationService.sendNotificationToUser(
      userId: taskOwnerId,
      title: "New Proposal Received",
      body: "$proposerName sent a proposal for: $taskTitle",
      data: {
        'notification_type': 'mutual_task_proposal_received',
        'task_id': taskId,
        'proposer_name': proposerName,
        'task_title': taskTitle,
      },
      senderId: proposerId,
    );
  }

  // ==================== CHAT MODULE NOTIFICATIONS ====================

  /// Send notification for new chat message
  static Future<void> notifyNewMessage({
    required String recipientId,
    required String messagePreview,
    required String conversationId,
    required String senderId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Check if user has chat notifications enabled
    final isEnabled = await _firestoreService.isNotificationEnabled(recipientId, 'chat_notifications');
    if (!isEnabled) return;

    // Get sender name
    final senderDoc = await _firestoreService.getUser(senderId);
    final senderName = senderDoc?.displayName ?? 'Someone';

    await _notificationService.sendNotificationToUser(
      userId: recipientId,
      title: "New Message from $senderName",
      body: messagePreview.length > 50 ? "${messagePreview.substring(0, 50)}..." : messagePreview,
      data: {
        'notification_type': 'new_message',
        'conversation_id': conversationId,
        'sender_id': senderId,
        'sender_name': senderName,
        'message_preview': messagePreview,
      },
      senderId: senderId,
    );
  }

  /// Send notification for multiple new messages (batch)
  static Future<void> notifyNewMessages({
    required List<String> recipientIds,
    required String messagePreview,
    required String conversationId,
    required String senderId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Filter users who have chat notifications enabled
    final enabledUserIds = <String>[];
    for (final userId in recipientIds) {
      final isEnabled = await _firestoreService.isNotificationEnabled(userId, 'chat_notifications');
      if (isEnabled) {
        enabledUserIds.add(userId);
      }
    }

    if (enabledUserIds.isEmpty) return;

    // Get sender name
    final senderDoc = await _firestoreService.getUser(senderId);
    final senderName = senderDoc?.displayName ?? 'Someone';

    await _notificationService.sendNotificationToMultipleUsers(
      userIds: enabledUserIds,
      title: "New Message from $senderName",
      body: messagePreview.length > 50 ? "${messagePreview.substring(0, 50)}..." : messagePreview,
      data: {
        'notification_type': 'new_message',
        'conversation_id': conversationId,
        'sender_id': senderId,
        'sender_name': senderName,
        'message_preview': messagePreview,
      },
      senderId: senderId,
    );
  }

  // ==================== UTILITY METHODS ====================

  /// Get user's FCM token
  static Future<String?> getUserFCMToken(String userId) async {
    return await _firestoreService.getFCMToken(userId);
  }

  /// Update user's FCM token
  static Future<bool> updateUserFCMToken(String userId, String? token) async {
    return await _firestoreService.updateFCMToken(userId, token);
  }

  /// Get user notifications from SharedPreferences
  static Future<List<Map<String, dynamic>>> getUserNotifications(String userId) async {
    return await _notificationService.getUserNotifications(userId: userId);
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead({
    required String userId,
    required String notificationId,
  }) async {
    await _notificationService.markNotificationAsRead(
      userId: userId,
      notificationId: notificationId,
    );
  }

  /// Mark all notifications as read
  static Future<void> markAllNotificationsAsRead({
    required String userId,
  }) async {
    await _notificationService.markAllNotificationsAsRead(
      userId: userId,
    );
  }

  /// Delete notification
  static Future<void> deleteNotification({
    required String userId,
    required String notificationId,
  }) async {
    await _notificationService.deleteNotification(
      userId: userId,
      notificationId: notificationId,
    );
  }

  /// Delete all notifications
  static Future<void> clearAllNotifications(String userId) async {
    await _notificationService.deleteAllNotifications(
      userId: userId,
    );
  }

  /// Check if user has notification permission
  static Future<bool> hasNotificationPermission(String userId) async {
    try {
      final userDoc = await _firestoreService.getUser(userId);
      return userDoc != null;
    } catch (e) {
      return true; // Default to enabled if error
    }
  }

  /// Update notification settings
  static Future<void> updateNotificationSettings({
    required String userId,
    required bool enabled,
  }) async {
    try {
      // Update all notification preferences
      final preferences = {
        'task_notifications': enabled,
        'chat_notifications': enabled,
        'system_notifications': enabled,
        'mutual_task_notifications': enabled,
      };
      
      await _firestoreService.updateNotificationPreferences(userId, preferences);
    } catch (e) {
      print('Error updating notification settings: $e');
    }
  }

  /// Update specific notification preference
  static Future<bool> updateNotificationPreference(String userId, String type, bool enabled) async {
    return await _firestoreService.updateNotificationPreference(userId, type, enabled);
  }

  /// Get user's notification preferences
  static Future<Map<String, bool>?> getNotificationPreferences(String userId) async {
    return await _firestoreService.getNotificationPreferences(userId);
  }

  /// Check if specific notification type is enabled for user
  static Future<bool> isNotificationTypeEnabled(String userId, String type) async {
    return await _firestoreService.isNotificationEnabled(userId, type);
  }

  // ==================== TEST NOTIFICATIONS ====================

  /// Send a test notification to verify the system works
  static Future<void> sendTestNotification({
    required String userId,
    String? customMessage,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await _notificationService.sendNotificationToUser(
      userId: userId,
      title: "Test Notification",
      body: customMessage ?? "This is a test notification to verify the system works!",
      data: {
        'notification_type': 'test',
        'timestamp': DateTime.now().toIso8601String(),
        'test': true,
      },
      senderId: currentUser.uid,
    );
  }

  /// Send test notification to current user
  static Future<void> sendTestNotificationToCurrentUser({
    String? customMessage,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await sendTestNotification(
      userId: currentUser.uid,
      customMessage: customMessage,
    );
  }
} 