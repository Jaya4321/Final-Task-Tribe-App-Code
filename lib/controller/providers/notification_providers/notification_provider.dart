import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_tribe_app/services/notification_service.dart';
import 'package:task_tribe_app/services/notification_helper.dart';

/// Notification provider for managing notification state and settings
class NotificationProvider extends ChangeNotifier {
  final NotificationServices _notificationService = NotificationServices.instance;
  
  // State variables
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _notificationEnabled = true;
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  String? _error;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get notificationEnabled => _notificationEnabled;
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  String? get error => _error;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _setLoading(true);
      _clearError();

      await _notificationService.initialize(
        onMessageReceived: _handleForegroundMessage,
        onMessageOpenedApp: _handleNotificationTap,
        onNotificationTapped: _handleLocalNotificationTap,
        onOpenedApp: _handleAppOpened,
      );

      // Load user's notification settings
      await _loadNotificationSettings();
      
      // Start listening to notifications
      _startListeningToNotifications();

      _isInitialized = true;
      _setLoading(false);
    } catch (e) {
      _setError('Failed to initialize notifications: $e');
      _setLoading(false);
    }
  }

  /// Load user's notification settings
  Future<void> _loadNotificationSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final hasPermission = await NotificationHelper.hasNotificationPermission(user.uid);
      _notificationEnabled = hasPermission;
      notifyListeners();
    } catch (e) {
      print('Error loading notification settings: $e');
    }
  }

  /// Start listening to user's notifications
  void _startListeningToNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final notifications = await NotificationHelper.getUserNotifications(user.uid);
      _notifications = notifications;
      _updateUnreadCount();
      notifyListeners();
    } catch (error) {
      _setError('Error loading notifications: $error');
    }
  }

  /// Update unread count
  void _updateUnreadCount() {
    _unreadCount = _notifications.where((notification) => 
      notification['isRead'] == false
    ).length;
  }

  /// Handle foreground message
  void _handleForegroundMessage(dynamic message) {
    try {
      final data = message.data as Map<String, dynamic>;
      final notificationType = data['notification_type'];
      
      print('Received foreground message: $notificationType');
      
      // Update notifications list if needed
      _refreshNotifications();
    } catch (e) {
      print('Error handling foreground message: $e');
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(dynamic message) {
    try {
      final data = message.data as Map<String, dynamic>;
      final notificationType = data['notification_type'];
      
      print('Notification tapped: $notificationType');
      
      // Navigate based on notification type
      _navigateBasedOnNotificationType(data);
      
      // Mark as read
      _markNotificationAsRead(data);
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  /// Handle local notification tap
  void _handleLocalNotificationTap(dynamic response) {
    try {
      if (response.payload != null) {
        final data = jsonDecode(response.payload!);
        final notificationType = data['notification_type'];
        
        print('Local notification tapped: $notificationType');
        
        // Navigate based on notification type
        _navigateBasedOnNotificationType(data);
        
        // Mark as read
        _markNotificationAsRead(data);
      }
    } catch (e) {
      print('Error handling local notification tap: $e');
    }
  }

  /// Handle app opened without notification
  void _handleAppOpened() {
    print('App opened without notification');
  }

  /// Navigate based on notification type
  void _navigateBasedOnNotificationType(Map<String, dynamic> data) {
    try {
      final notificationType = data['notification_type'];
      
      switch (notificationType) {
        case 'task_assigned':
        case 'task_accepted':
        case 'task_delivered':
        case 'task_reviewed':
        case 'task_hired':
        case 'task_not_hired':
        case 'task_application':
        case 'delivery_accepted':
        case 'delivery_rejected':
          final taskId = data['task_id'];
          if (taskId != null) {
            // Navigate to task details screen
            print('Navigate to task details: $taskId');
            // TODO: Implement navigation to task details screen
          }
          break;
          
        case 'mutual_task_proposal_accepted':
        case 'mutual_task_proposal_rejected':
        case 'mutual_task_proposal_received':
          final taskId = data['task_id'];
          if (taskId != null) {
            // Navigate to mutual task details screen
            print('Navigate to mutual task details: $taskId');
            // TODO: Implement navigation to mutual task details screen
          }
          break;
          
        case 'new_message':
          final conversationId = data['conversation_id'];
          final senderId = data['sender_id'];
          if (conversationId != null) {
            // Navigate to chat screen
            print('Navigate to chat: $conversationId');
            // TODO: Implement navigation to chat screen
          }
          break;
          
        default:
          print('Unknown notification type: $notificationType');
      }
    } catch (e) {
      print('Error navigating based on notification type: $e');
    }
  }

  /// Mark notification as read
  Future<void> _markNotificationAsRead(Map<String, dynamic> data) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notificationId = data['notification_id'];
      if (notificationId != null) {
        await NotificationHelper.markNotificationAsRead(
          userId: user.uid,
          notificationId: notificationId,
        );
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Refresh notifications
  Future<void> _refreshNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // The stream will automatically update the notifications list
      // This is just a placeholder for manual refresh if needed
    } catch (e) {
      print('Error refreshing notifications: $e');
    }
  }

  /// Toggle notification settings
  Future<void> toggleNotificationSettings() async {
    try {
      _setLoading(true);
      _clearError();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _notificationEnabled = !_notificationEnabled;
      
      await NotificationHelper.updateNotificationSettings(
        userId: user.uid,
        enabled: _notificationEnabled,
      );

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to update notification settings: $e');
      _setLoading(false);
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await NotificationHelper.markNotificationAsRead(
        userId: user.uid,
        notificationId: notificationId,
      );
    } catch (e) {
      _setError('Failed to mark notification as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await NotificationHelper.deleteNotification(
        userId: user.uid,
        notificationId: notificationId,
      );
    } catch (e) {
      _setError('Failed to delete notification: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      _setLoading(true);
      _clearError();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await NotificationHelper.clearAllNotifications(user.uid);
      
      _setLoading(false);
    } catch (e) {
      _setError('Failed to clear notifications: $e');
      _setLoading(false);
    }
  }

  /// Send test notification
  Future<void> sendTestNotification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _notificationService.sendNotificationToUser(
        userId: user.uid,
        title: "Test Notification",
        body: "This is a test notification from TaskTribe",
        data: {
          'notification_type': 'system_update',
          'test': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
        senderId: user.uid,
      );
    } catch (e) {
      _setError('Failed to send test notification: $e');
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Dispose
  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
} 