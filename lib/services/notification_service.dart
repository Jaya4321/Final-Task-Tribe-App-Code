import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firestore_service.dart';

/// Enum for notification types
enum NotificationType {
  // Task-related notifications
  taskAssigned,
  taskAccepted,
  taskDelivered,
  taskReviewed,
  taskHired,
  taskNotHired,
  
  // Mutual task notifications
  mutualTaskProposalAccepted,
  mutualTaskProposalRejected,
  mutualTaskProposalReceived,
  
  // Chat notifications
  newMessage,
  messageRead,
  
  // System notifications
  systemUpdate,
  maintenance,
}

/// Enhanced notification service following best practices
class NotificationServices {
  static NotificationServices? _instance;

  final Completer<void> _initCompleter = Completer<void>();
  bool _isInitialized = false;

  // Firebase Messaging instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Flutter Local Notifications instance
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Firestore Service instance
  final FirestoreService _firestoreService = FirestoreService();
  
  // Service account credentials for sending notifications
  static const String _projectId = 'final-imp'; // Replace with your project ID
  static const String _fcmUrl = 'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';
  
  // Service account credentials (store securely in production)
  static const Map<String, dynamic> _serviceAccountCredentials = {
    "type": "service_account",
    "project_id": "final-imp",
    "private_key_id": "894e519985b959740ce25c68d3ca1ed200d1017b",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCvlS/dWlsAwAnf\nOGSC9xpUnuOEQ+xlWiPbNRVAf5MfpmdpIP19VTVjUIelKx8E1aEDNGgTzkKMBWzb\nu8cMjYMYxpfQ8ReB3VJJouDQKbZqkTv99ZmCEGXZnwso277ClQpzsYxSZG+TpFiJ\nU0yn1jaLD+Z1Df5iXSZ+SV+aFCOJ1RXm6YXK0iP4VY3majQcveLoMwRgl/R3Vyv3\nohzrnLiLLwdckOaO2+g6hz3pDbIyyP3SFv8VR7uJHAAGnPL/j3IclD+5XnVjN5A4\noMCffcK9zTZFhUDLXpXOdIJ4FtLRzoKK8iAV/4bJV3NvJOteMt12P4OPwkJZTNV4\n+vWw9PKFAgMBAAECggEABqEo6gAv4HLfzIxaCzHeTiSjrYpNAjSpluzFrSZD/VVw\noSEMQS+28NWJEZzzsmCIkFDpvxmyHIxV5GQOK3SqZwSUleCMhSxAn6QlPebdSt/J\n9phP3//TgKiHKNdHOBydhOnGxROivN3fM+wvwESP0adbib7qBHfE7M7Da9Nn1hvk\nDZ4UFzdduCKmwxTbErgFhn24Ru8oZb++1A1NkrA17KqznSlBlKoiWxSzqqlHscn2\nbmsivT6VX0IVsqPek9TSfNb273gVnYSLPcd9fX/GL+RQJdOXWNPGMLsSHiobjkCo\nJXPJvOy+c7XWFD+ceIsKd2sVkxPx+H64IzQfTB1k/wKBgQDdrEhI3NFGF+FCKe/z\n1G4jpc1TOSK1iuvyXVZc8nGU3kzF9ute52WNRmdagMMWFDtKiz1N0kfepv30L79O\n3Obeg6MUJKrYOHCD26FfhUGEFVkclyyODlmNRlZDha1jgHPMG1cA33r90otibjto\nDUviyMuvDRE72hoNbkpTAvPhPwKBgQDKxcN1zLH9Hr9qOz/wJg7a++s5mH1VLRBH\npFFFli8plb+e4hCh/eB/jfTghlnH7O4zhZbK09rq0HuTCDT8kZ/nsJYnI597sFJg\nLij9/lOoeb5TSooHRQz/YBsN78AbiJPUlPXH3+1zjbVhOW5GaqlRosqT/UivjIZB\njtPCKES3OwKBgBTlgsLrnga/hYqZLXeM1P0jSiHIRw9aEzf7uIJ2kGJ6Oj6HMlT1\n90rEEkYj0UAplBVI3vSRGBlTIKl+PsiOZm0fd6YUds5/M4wajjHU/AIZiRb64UZa\n7/IzaTpgRaIVn9Tj1uXMK2n2CRG0VoFOj5LHXvwXfUJpIv+VIAiHRLo9AoGAT5My\ntK0DAJmrds4PtnfJBqksU6sDLIUFyYezmUJp+cDZtUl0S44tJwGXovE2lJ3nkPKR\nDcH8PIBaroXe/WtMvIjxNCTntouomDQlRCAlxo0YYulyp42ynxmhJGP9GRENKrTW\ni3zWW622C5SVMS80iWQAaflRKAtWuK2LbruM0/cCgYEAkNLD+wzCYJP7qlwj6wsn\ntaYPAGqg3x8uBv1Z9T8l7x6Ku2gEqmKSajUJ8pIY2dMQVwYKuPjKne1IwYu1+kBl\nnaLvsXz7oxpf0cbB5YZC+mEnKmy/RKrQKZJ+TpXRq7AbDEBzIx/VW1Vuf9qX/NLL\npT4immfseczz7gEn6wuM9kk=\n-----END PRIVATE KEY-----\n",
    "client_email": "firebase-adminsdk-fbsvc@final-imp.iam.gserviceaccount.com",
    "client_id": "112382069766568645821",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40final-imp.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com"
  };

  // Callbacks
  Function(dynamic)? _onMessageReceived;
  Function(dynamic)? _onMessageOpenedApp;
  Function()? _onOpenedApp;
  Function(dynamic)? _onNotificationTapped;

  NotificationServices._();

  /// Singleton instance getter
  static NotificationServices get instance {
    _instance ??= NotificationServices._();
    return _instance!;
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Wait for initialization to complete
  Future<void> get initialized => _initCompleter.future;

  /// Initialize the notification service
  Future<void> initialize({
    Function(dynamic)? onMessageReceived,
    Function(dynamic)? onMessageOpenedApp,
    Function(dynamic)? onNotificationTapped,
    Function()? onOpenedApp,
  }) async {
    if (_isInitialized) {
      developer.log('NotificationServices already initialized');
      return;
    }

    try {
      // Store callbacks
      _onMessageReceived = onMessageReceived;
      _onMessageOpenedApp = onMessageOpenedApp;
      _onNotificationTapped = onNotificationTapped;
      _onOpenedApp = onOpenedApp;

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize in sequence
      await _setupFirebaseMessaging();
      await _requestPermission();
      await _getAndUpdateToken();

      _isInitialized = true;
      _initCompleter.complete();

      developer.log('NotificationServices initialized successfully');
    } catch (e) {
      developer.log('Failed to initialize NotificationServices: $e');
      _initCompleter.completeError(e);
      rethrow;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    developer.log('FlutterLocalNotificationsPlugin initialized');
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      developer.log('Notification permission status: ${settings.authorizationStatus}');
      
      // Create notification channels for Android
      await _createNotificationChannels();
    } catch (e) {
      developer.log('Failed to request notification permission: $e');
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    try {
      // This would normally be done with flutter_local_notifications
      // For now, we'll rely on Firebase to handle the channel creation
      developer.log('Notification channels will be created by Firebase');
    } catch (e) {
      developer.log('Failed to create notification channels: $e');
    }
  }

  /// Get and update FCM token
  Future<void> _getAndUpdateToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        developer.log('FCM Token: $token');
        // Store token locally for now - you can update user's FCM token in Firestore here
      }
    } catch (e) {
      developer.log('Failed to get FCM token: $e');
    }
  }

  /// Setup Firebase Messaging
  Future<void> _setupFirebaseMessaging() async {
    try {
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        developer.log('Received foreground message: ${message.messageId}');
        
        // Show system notification for foreground messages
        await _showLocalNotification(message);
        
        _onMessageReceived?.call(message);
      });

      // Handle when app is opened from background notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        developer.log('App opened from background notification: ${message.messageId}');
        _onMessageOpenedApp?.call(message);
      });

      // Handle when app is opened without notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        developer.log('App opened without notification: ${initialMessage.messageId}');
        _onOpenedApp?.call();
      }

      developer.log('Firebase Messaging setup completed');
    } catch (e) {
      developer.log('Failed to setup Firebase Messaging: $e');
    }
  }

  /// Show a local notification using flutter_local_notifications
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'default_channel',
        'Default',
        channelDescription: 'Default channel for notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        0,
        notification.title,
        notification.body,
        platformChannelSpecifics,
        payload: message.data.toString(),
      );
      developer.log('Local notification shown for foreground message');
    } catch (e) {
      developer.log('Failed to show local notification: $e');
    }
  }

  /// Get access token for FCM
  Future<String?> _getAccessToken() async {
    try {
      final credentials = ServiceAccountCredentials.fromJson(_serviceAccountCredentials);
      final client = await clientViaServiceAccount(credentials, [
        'https://www.googleapis.com/auth/firebase.messaging',
      ]);

      final token = client.credentials.accessToken.data;
      client.close();
      return token;
    } catch (e) {
      developer.log('Failed to get access token: $e');
      return null;
    }
  }

  /// Send notification to a specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    String? senderId,
  }) async {
    try {
      // Get user's FCM token from Firestore
      final userToken = await _firestoreService.getFCMToken(userId);
      developer.log('FCM token for user $userId: ${userToken != null ? 'Found' : 'NOT FOUND'}');
      
      if (userToken == null) {
        developer.log('No FCM token found for user $userId');
        return;
      }

      developer.log('Sending notification to user $userId: $title');
      developer.log('User FCM token: ${userToken.substring(0, 20)}...');
      
      // Send FCM notification
      await _sendFCMNotification(
        token: userToken,
        title: title,
        body: body,
        data: data,
      );

      // Store notification locally using SharedPreferences
      await _storeNotificationLocally(userId, title, body, data, senderId);
    } catch (e) {
      developer.log('Failed to send notification to user: $e');
    }
  }

  /// Send notification to multiple users
  Future<void> sendNotificationToMultipleUsers({
    required List<String> userIds,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    String? senderId,
  }) async {
    try {
      // Get FCM tokens for all users
      final List<String> validTokens = [];
      for (final userId in userIds) {
        final token = await _firestoreService.getFCMToken(userId);
        if (token != null && token.isNotEmpty) {
          validTokens.add(token);
        }
      }

      if (validTokens.isEmpty) {
        developer.log('No valid FCM tokens found for users: $userIds');
        return;
      }

      developer.log('Sending notification to ${validTokens.length} users: $title');

      // Send FCM notifications to all valid tokens
      for (final token in validTokens) {
        await _sendFCMNotification(
          token: token,
          title: title,
          body: body,
          data: data,
        );
      }

      // Store notification locally for each user
      for (final userId in userIds) {
        await _storeNotificationLocally(userId, title, body, data, senderId);
      }
    } catch (e) {
      developer.log('Failed to send notification to multiple users: $e');
    }
  }

  /// Sanitize string to avoid encoding issues
  String _sanitizeString(String input) {
    // Replace problematic characters that might cause encoding issues
    return input
        .replaceAll('⭐', '*')  // Replace star emoji with asterisk
        .replaceAll('🌟', '*')  // Replace star emoji with asterisk
        .replaceAll('💫', '*')  // Replace star emoji with asterisk
        .replaceAll('✨', '*')  // Replace star emoji with asterisk
        .replaceAll('🔥', '!')  // Replace fire emoji with exclamation
        .replaceAll('💯', '100') // Replace 100 emoji with text
        .replaceAll('👍', 'Good') // Replace thumbs up with text
        .replaceAll('👎', 'Bad')  // Replace thumbs down with text
        .replaceAll('✅', 'Done') // Replace checkmark with text
        .replaceAll('❌', 'Failed') // Replace X with text
        .replaceAll('⚠️', 'Warning') // Replace warning with text
        .replaceAll('🚀', 'Great') // Replace rocket with text
        .replaceAll('🎉', 'Congratulations') // Replace party with text
        .replaceAll('💪', 'Strong') // Replace muscle with text
        .replaceAll('🎯', 'Target') // Replace target with text
        .replaceAll('📱', 'App') // Replace mobile with text
        .replaceAll('💻', 'Computer') // Replace computer with text
        .replaceAll('📧', 'Email') // Replace email with text
        .replaceAll('📞', 'Phone') // Replace phone with text
        .replaceAll('📍', 'Location') // Replace location with text
        .replaceAll('⏰', 'Time') // Replace clock with text
        .replaceAll('📅', 'Date') // Replace calendar with text
        .replaceAll('💰', 'Money') // Replace money with text
        .replaceAll('💎', 'Premium') // Replace gem with text
        .replaceAll('🏆', 'Winner') // Replace trophy with text
        .replaceAll('🥇', 'Gold') // Replace gold medal with text
        .replaceAll('🥈', 'Silver') // Replace silver medal with text
        .replaceAll('🥉', 'Bronze'); // Replace bronze medal with text
  }

  /// Send FCM notification
  Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        developer.log('Failed to get access token for FCM');
        return;
      }

      // Sanitize title and body to avoid encoding issues
      final sanitizedTitle = _sanitizeString(title);
      final sanitizedBody = _sanitizeString(body);

      // Minimal FCM v1 API payload
      final requestBody = {
        'message': {
          'token': token,
          'notification': {
            'title': sanitizedTitle,
            'body': sanitizedBody,
          },
          'data': data.map((key, value) => MapEntry(key, value.toString())),
        }
      };

      final jsonString = json.encode(requestBody);
      developer.log('Sending FCM request: $jsonString');

      final request = await HttpClient().openUrl('POST', Uri.parse(_fcmUrl));
      request.headers.set('Authorization', 'Bearer $accessToken');
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonString);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      developer.log('FCM response: ${response.statusCode} - $responseBody');

      if (response.statusCode == 200) {
        developer.log('FCM notification sent successfully!');
      } else {
        developer.log('FCM request failed: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      developer.log('Failed to send FCM notification: $e');
    }
  }

  /// Store notification locally using SharedPreferences
  Future<void> _storeNotificationLocally(
    String userId,
    String title,
    String body,
    Map<String, dynamic> data,
    String? senderId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notifications_$userId';
      
      // Get existing notifications
      final existingJson = prefs.getString(key) ?? '[]';
      final List<dynamic> notifications = json.decode(existingJson);
      
      // Create new notification
      final notification = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'body': body,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'senderId': senderId ?? '',
        'isRead': false,
      };
      
      // Add to beginning of list (most recent first)
      notifications.insert(0, notification);
      
      // Keep only last 100 notifications
      if (notifications.length > 100) {
        notifications.removeRange(100, notifications.length);
      }
      
      // Save back to SharedPreferences
      await prefs.setString(key, json.encode(notifications));
      
      developer.log('Notification stored locally for user $userId');
    } catch (e) {
      developer.log('Failed to store notification locally: $e');
    }
  }

  /// Get user notifications from SharedPreferences
  Future<List<Map<String, dynamic>>> getUserNotifications({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notifications_$userId';
      
      final jsonString = prefs.getString(key) ?? '[]';
      final List<dynamic> notifications = json.decode(jsonString);
      
      return notifications
          .take(limit)
          .map((notification) => Map<String, dynamic>.from(notification))
          .toList();
    } catch (e) {
      developer.log('Failed to get user notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead({
    required String userId,
    required String notificationId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notifications_$userId';
      
      final jsonString = prefs.getString(key) ?? '[]';
      final List<dynamic> notifications = json.decode(jsonString);
      
      // Find and update the notification
      for (int i = 0; i < notifications.length; i++) {
        if (notifications[i]['id'] == notificationId) {
          notifications[i]['isRead'] = true;
          break;
        }
      }
      
      await prefs.setString(key, json.encode(notifications));
      developer.log('Notification marked as read: $notificationId');
    } catch (e) {
      developer.log('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead({
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notifications_$userId';
      
      final jsonString = prefs.getString(key) ?? '[]';
      final List<dynamic> notifications = json.decode(jsonString);
      
      // Mark all notifications as read
      for (int i = 0; i < notifications.length; i++) {
        notifications[i]['isRead'] = true;
      }
      
      await prefs.setString(key, json.encode(notifications));
      developer.log('All notifications marked as read for user $userId');
    } catch (e) {
      developer.log('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification({
    required String userId,
    required String notificationId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notifications_$userId';
      
      final jsonString = prefs.getString(key) ?? '[]';
      final List<dynamic> notifications = json.decode(jsonString);
      
      // Remove the notification
      notifications.removeWhere((notification) => notification['id'] == notificationId);
      
      await prefs.setString(key, json.encode(notifications));
      developer.log('Notification deleted: $notificationId');
    } catch (e) {
      developer.log('Failed to delete notification: $e');
    }
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications({
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notifications_$userId';
      
      await prefs.remove(key);
      developer.log('All notifications deleted for user $userId');
    } catch (e) {
      developer.log('Failed to delete all notifications: $e');
    }
  }

  /// Dispose the service
  void dispose() {
    _isInitialized = false;
    _onMessageReceived = null;
    _onMessageOpenedApp = null;
    _onNotificationTapped = null;
    _onOpenedApp = null;
    developer.log('NotificationServices disposed');
  }
} 