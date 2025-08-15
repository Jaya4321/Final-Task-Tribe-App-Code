import 'package:flutter/material.dart';
import 'myColors.dart';

// Chat Message Types
enum MessageType {
  text,
  image,
  voice,
  file,
}

// Message Status
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

// Chat UI Constants
class ChatUIConstants {
  // Spacing
  static const double messagePadding = 12.0;
  static const double messageMargin = 8.0;
  static const double bubbleBorderRadius = 16.0;
  static const double inputBorderRadius = 24.0;

  // Typography
  static const double messageFontSize = 16.0;
  static const double timestampFontSize = 12.0;
  static const double userNameFontSize = 14.0;

  // Sizes
  static const double avatarSize = 40.0;
  static const double messageMaxWidth = 280.0;
  static const double inputHeight = 56.0;
  static const double sendButtonSize = 40.0;

  // Colors
  static const Color sentMessageColor = primaryColor;
  static const Color receivedMessageColor = Color(0xFFF0F0F0);
  static const Color sentMessageTextColor = Colors.white;
  static const Color receivedMessageTextColor = textPrimaryColor;

  // Animation
  static const Duration messageAnimationDuration = Duration(milliseconds: 300);
  static const Duration typingAnimationDuration = Duration(milliseconds: 600);
}

// Chat Empty State Messages
class ChatEmptyStateMessages {
  static const String noConversationsTitle = 'No conversations yet';
  static const String noConversationsSubtitle = 'Start chatting with task posters to get help with your tasks';
  static const String noMessagesTitle = 'No messages yet';
  static const String noMessagesSubtitle = 'Send a message to start the conversation';
  static const String startChatting = 'Start Chatting';
  static const String browseTasks = 'Browse Tasks';
}

// Chat Error Messages
class ChatErrorMessages {
  static const String failedToLoadConversations = 'Failed to load conversations';
  static const String failedToLoadMessages = 'Failed to load messages';
  static const String failedToSendMessage = 'Failed to send message';
  static const String failedToDeleteMessage = 'Failed to delete message';
  static const String failedToEditMessage = 'Failed to edit message';
  static const String failedToContactPoster = 'Failed to contact poster';
  static const String networkError = 'Network error. Please check your connection.';
  static const String unknownError = 'An unexpected error occurred';
}

// Chat Success Messages
class ChatSuccessMessages {
  static const String messageSent = 'Message sent';
  static const String messageDeleted = 'Message deleted';
  static const String messageEdited = 'Message edited';
  static const String conversationStarted = 'Conversation started';
}

// Chat Validation Messages
class ChatValidationMessages {
  static const String messageEmpty = 'Message cannot be empty';
  static const String messageTooLong = 'Message is too long (max 1000 characters)';
  static const String invalidMessageContent = 'Invalid message content';
}

// Chat Limits
class ChatLimits {
  static const int maxMessageLength = 1000;
  static const int maxMessagesPerLoad = 50;
  static const int typingIndicatorDelay = 1000; // milliseconds
  static const int messageRetryAttempts = 3;
}

// Chat Animation Durations
class ChatAnimationDurations {
  static const Duration messageSend = Duration(milliseconds: 300);
  static const Duration messageReceive = Duration(milliseconds: 300);
  static const Duration typingIndicator = Duration(milliseconds: 600);
  static const Duration scrollToBottom = Duration(milliseconds: 300);
  static const Duration fadeIn = Duration(milliseconds: 200);
  static const Duration fadeOut = Duration(milliseconds: 200);
}

// Block User Messages
class BlockUserMessages {
  static const String userBlocked = 'User blocked successfully';
  static const String userUnblocked = 'User unblocked successfully';
  static const String failedToBlock = 'Failed to block user';
  static const String failedToUnblock = 'Failed to unblock user';
  static const String blockedByUser = 'You have been blocked by this user';
  static const String hasBlockedUser = 'You have blocked this user';
  static const String cannotContactBlocked = 'Cannot contact this user due to blocking';
  static const String unblockToContact = 'You have blocked this user. Unblock them to start a conversation.';
  static const String cannotSendToBlocked = 'Cannot send message to blocked user';
}

// Block User Dialog Messages
class BlockUserDialogMessages {
  static const String blockUserTitle = 'Block User';
  static const String unblockUserTitle = 'Unblock User';
  static const String blockUserMessage = 'Are you sure you want to block this user? You will not be able to send or receive messages from them.';
  static const String unblockUserMessage = 'Are you sure you want to unblock this user? You will be able to send and receive messages from them again.';
  static const String blockConfirm = 'Block';
  static const String unblockConfirm = 'Unblock';
  static const String cancel = 'Cancel';
}

// Block User UI Constants
class BlockUserUIConstants {
  static const Color blockBannerColor = Color(0xFFFFEBEE); // Light red
  static const Color unblockBannerColor = Color(0xFFFFF3E0); // Light orange
  static const Color blockTextColor = Color(0xFFD32F2F); // Dark red
  static const Color unblockTextColor = Color(0xFFE65100); // Dark orange
  static const double bannerPadding = 12.0;
  static const double bannerIconSize = 20.0;
} 