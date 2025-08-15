import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/providers/chat_providers/chat_provider.dart';
import '../controller/providers/authentication_providers/auth_provider.dart';
import '../view/screens/chat_screens/chat_room_screen.dart';
import '../utils/auth_helpers.dart';
import '../services/firestore_service.dart';
import '../constants/chat_constants.dart';

class ChatHelpers {
  static final FirestoreService _firestoreService = FirestoreService();

  // Handle contact poster button click
  static Future<void> handleContactPosterButton({
    required BuildContext context,
    required String posterId,
    String? taskTitle,
  }) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        AuthHelpers.showErrorToast('Please sign in to contact the poster');
        return;
      }

      final currentUserId = currentUser.uid;
      
      // Set current user ID in chat provider and ensure data is cleared
      chatProvider.setCurrentUserId(currentUserId);
      
      // Check if user is trying to contact themselves
      if (currentUserId == posterId) {
        AuthHelpers.showErrorToast('You cannot contact yourself');
        return;
      }

      // Check if users are blocked
      final areBlocked = await _firestoreService.areUsersBlocked(currentUserId, posterId);
      if (areBlocked) {
        final isUserBlocked = await _firestoreService.isUserBlocked(posterId, currentUserId);
        final hasBlockedUser = await _firestoreService.isUserBlocked(currentUserId, posterId);
        
        if (isUserBlocked) {
          AuthHelpers.showErrorToast(BlockUserMessages.blockedByUser);
        } else if (hasBlockedUser) {
          AuthHelpers.showErrorToast(BlockUserMessages.unblockToContact);
        } else {
          AuthHelpers.showErrorToast(BlockUserMessages.cannotContactBlocked);
        }
        return;
      }

      // Show loading indicator
      AuthHelpers.showLoadingDialog(
        context: context,
        message: 'Setting up chat...',
      );

      // Handle contact poster functionality
      final conversationId = await chatProvider.handleContactPoster(currentUserId, posterId);
      
      // Hide loading dialog
      Navigator.of(context).pop();

      if (conversationId != null) {
        // Get poster's display name for the chat
        final posterName = await _getUserDisplayName(posterId);
        
        // Navigate to chat room
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(
              chatId: conversationId,
              userName: posterName,
              taskTitle: taskTitle ?? 'Task Discussion',
            ),
          ),
        );
      } else {
        AuthHelpers.showErrorToast('Failed to start conversation');
      }
    } catch (e) {
      print('DEBUG: Error in handleContactPosterButton: $e');
      AuthHelpers.showErrorToast('Failed to contact poster: $e');
    }
  }

  // Get user display name from Firestore
  static Future<String> _getUserDisplayName(String userId) async {
    try {
      final user = await _firestoreService.getUser(userId);
      return user?.displayName ?? 'User';
    } catch (e) {
      return 'User';
    }
  }

  // Get conversation ID for two users
  static String getConversationId(String user1Id, String user2Id) {
    final List<String> participants = [user1Id, user2Id];
    participants.sort();
    return '${participants[0]}_${participants[1]}';
  }

  // Format conversation last message
  static String formatLastMessage(String message, int maxLength) {
    if (message.length <= maxLength) {
      return message;
    }
    return '${message.substring(0, maxLength)}...';
  }

  // Format conversation timestamp
  static String formatConversationTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Get user initials from display name
  static String getUserInitials(String? displayName) {
    if (displayName == null || displayName.isEmpty) {
      return '?';
    }
    
    final words = displayName.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
    }
  }

  // Validate message content
  static bool isValidMessageContent(String content) {
    return content.trim().isNotEmpty && content.length <= 1000;
  }

  // Get message validation error
  static String? getMessageValidationError(String content) {
    if (content.trim().isEmpty) {
      return 'Message cannot be empty';
    }
    if (content.length > 1000) {
      return 'Message is too long (max 1000 characters)';
    }
    return null;
  }

  // Show message options dialog
  static Future<void> showMessageOptionsDialog({
    required BuildContext context,
    required String messageId,
    required String conversationId,
    required bool isOwnMessage,
    required VoidCallback onDelete,
    required VoidCallback onEdit,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Message Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOwnMessage) ...[
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Message'),
                  onTap: () {
                    Navigator.of(context).pop();
                    onEdit();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Message', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(context).pop();
                    onDelete();
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.report),
                  title: const Text('Report Message'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: Implement report functionality
                    AuthHelpers.showToast('Report functionality coming soon');
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Show block user confirmation dialog
  static Future<bool> showBlockUserDialog({
    required BuildContext context,
    required String userName,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(BlockUserDialogMessages.blockUserTitle),
        content: Text(BlockUserDialogMessages.blockUserMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(BlockUserDialogMessages.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(BlockUserDialogMessages.blockConfirm, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  // Show unblock user confirmation dialog
  static Future<bool> showUnblockUserDialog({
    required BuildContext context,
    required String userName,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(BlockUserDialogMessages.unblockUserTitle),
        content: Text(BlockUserDialogMessages.unblockUserMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(BlockUserDialogMessages.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(BlockUserDialogMessages.unblockConfirm, style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    ) ?? false;
  }

  // Check if users are blocked
  static Future<bool> areUsersBlocked(String user1Id, String user2Id) async {
    try {
      return await _firestoreService.areUsersBlocked(user1Id, user2Id);
    } catch (e) {
      return false;
    }
  }

  // Get block status for two users
  static Future<Map<String, bool>> getBlockStatus(String user1Id, String user2Id) async {
    try {
      final user1Blocked = await _firestoreService.isUserBlocked(user1Id, user2Id);
      final user2Blocked = await _firestoreService.isUserBlocked(user2Id, user1Id);
      
      return {
        'user1Blocked': user1Blocked,
        'user2Blocked': user2Blocked,
        'areBlocked': user1Blocked || user2Blocked,
      };
    } catch (e) {
      return {
        'user1Blocked': false,
        'user2Blocked': false,
        'areBlocked': false,
      };
    }
  }

  // Get chat bubble color based on message sender
  static Color getChatBubbleColor(bool isOwnMessage) {
    return isOwnMessage ? const Color(0xff2e49cd) : const Color(0xFFF0F0F0);
  }

  // Get chat bubble text color based on message sender
  static Color getChatBubbleTextColor(bool isOwnMessage) {
    return isOwnMessage ? Colors.white : const Color(0xFF212121);
  }

  // Get message status icon
  static IconData getMessageStatusIcon(bool seen) {
    return seen ? Icons.done_all : Icons.done;
  }

  // Get message status color
  static Color getMessageStatusColor(bool seen, bool isOwnMessage) {
    if (!isOwnMessage) return Colors.transparent;
    return seen ? const Color(0xff2e49cd) : Colors.grey;
  }

  // Check if message should show timestamp
  static bool shouldShowTimestamp(List<dynamic> messages, int currentIndex) {
    if (currentIndex == messages.length - 1) return true;
    
    final currentMessage = messages[currentIndex];
    final nextMessage = messages[currentIndex + 1];
    
    final timeDifference = currentMessage.timestamp.difference(nextMessage.timestamp);
    return timeDifference.inMinutes > 5;
  }

  // Get unread badge count
  static Widget getUnreadBadge(int count) {
    if (count == 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 