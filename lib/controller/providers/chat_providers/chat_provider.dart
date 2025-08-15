import 'package:flutter/material.dart';
import '../../../model/chat_models/chat_message_model.dart';
import '../../../model/chat_models/conversation_model.dart';
import '../../../services/chat_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/notification_helper.dart';
import '../../../model/authentication_models/user_model.dart';
import 'dart:async';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final FirestoreService _firestoreService = FirestoreService();
  
  // State variables
  List<ConversationModel> _conversations = [];
  List<ChatMessageModel> _messages = [];
  ConversationModel? _currentConversation;
  UserModel? _otherUser;
  
  bool _isLoading = false;
  bool _isSendingMessage = false;
  String? _errorMessage;
  String? _searchQuery;

  // Block status
  bool _isUserBlocked = false;
  bool _hasBlockedUser = false;

  // Add a cache for other user display names
  final Map<String, String> _conversationUserNames = {}; // conversationId -> otherUserDisplayName

  // Stream subscriptions for proper cleanup
  StreamSubscription<List<ConversationModel>>? _conversationsSubscription;
  StreamSubscription<List<ChatMessageModel>>? _messagesSubscription;

  // Getters
  List<ConversationModel> get conversations => _conversations;
  List<ChatMessageModel> get messages => _messages;
  ConversationModel? get currentConversation => _currentConversation;
  UserModel? get otherUser => _otherUser;
  
  bool get isLoading => _isLoading;
  bool get isSendingMessage => _isSendingMessage;
  String? get errorMessage => _errorMessage;
  String? get searchQuery => _searchQuery;

  // Block status getters
  bool get isUserBlocked => _isUserBlocked;
  bool get hasBlockedUser => _hasBlockedUser;
  bool get areUsersBlocked => _isUserBlocked || _hasBlockedUser;

  // Get cached user name for a conversation
  String getOtherUserName(String conversationId) {
    return _conversationUserNames[conversationId] ?? 'User';
  }

  // Refresh user names cache for all conversations
  Future<void> refreshUserNamesCache(String currentUserId) async {
    try {
      print('DEBUG: ChatProvider.refreshUserNamesCache called for currentUserId: $currentUserId');
      
      for (final conversation in _conversations) {
        await _refreshUserNamesForConversation(conversation.id, currentUserId);
      }
      
      print('DEBUG: ChatProvider.refreshUserNamesCache completed');
    } catch (e) {
      print('DEBUG: ChatProvider.refreshUserNamesCache error: $e');
      _setError('Failed to refresh user names: $e');
    }
  }

  // Refresh user names cache for a specific conversation
  Future<void> _refreshUserNamesForConversation(String conversationId, String currentUserId) async {
    try {
      print('DEBUG: ChatProvider._refreshUserNamesForConversation called for conversationId: $conversationId');
      
      final conversation = _conversations.firstWhere(
        (conv) => conv.id == conversationId,
        orElse: () => ConversationModel(
          id: '',
          participants: [],
          lastMessage: '',
          lastMessageTimestamp: DateTime.now(),
          lastMessageSenderId: '',
          unseenCount: {},
        ),
      );
      
      if (conversation.id.isNotEmpty) {
        final otherUserId = conversation.getOtherParticipant(currentUserId);
        final user = await _firestoreService.getUser(otherUserId);
        if (user != null) {
          _conversationUserNames[conversationId] = user.displayName ?? 'User';
          print('DEBUG: Refreshed user name for conversation $conversationId: ${user.displayName}');
        }
      }
    } catch (e) {
      print('DEBUG: Error refreshing user name for conversation $conversationId: $e');
    }
  }

  // Handle user login - initialize chat provider for new user
  Future<void> handleUserLogin(String userId) async {
    try {
      print('DEBUG: ChatProvider.handleUserLogin called for userId: $userId');
      
      // Clear any existing data and cancel subscriptions first
      await _clearAllDataAndSubscriptions();
      
      // Set current user ID
      setCurrentUserId(userId);
      
      // Load conversations for the new user
      await loadUserConversations(userId);
      
      print('DEBUG: ChatProvider.handleUserLogin completed for userId: $userId');
    } catch (e) {
      print('DEBUG: ChatProvider.handleUserLogin error: $e');
      // Don't set error here as it might be a temporary issue
      // Just clear the error and continue
      _clearError();
    }
  }

  // Refresh user names when returning to chat list
  Future<void> refreshUserNamesOnReturn(String userId) async {
    try {
      print('DEBUG: ChatProvider.refreshUserNamesOnReturn called for userId: $userId');
      await refreshUserNamesCache(userId);
      print('DEBUG: ChatProvider.refreshUserNamesOnReturn completed');
    } catch (e) {
      print('DEBUG: ChatProvider.refreshUserNamesOnReturn error: $e');
    }
  }

  // Get filtered conversations (search by last message or other user name)
  List<ConversationModel> get filteredConversations {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return _conversations;
    }
    final query = _searchQuery!.toLowerCase();
    return _conversations.where((conversation) {
      final otherName = getOtherUserName(conversation.id).toLowerCase();
      return conversation.lastMessage.toLowerCase().contains(query) ||
             otherName.contains(query);
    }).toList();
  }

  // Get unread conversations count
  int get unreadConversationsCount {
    return _conversations.where((conversation) => 
        conversation.hasUnreadMessages(_getCurrentUserId())).length;
  }

  // Get total unread messages count
  int get totalUnreadMessagesCount {
    int total = 0;
    for (final conversation in _conversations) {
      total += conversation.getUnreadCount(_getCurrentUserId());
    }
    return total;
  }

  // ========================================
  // CONVERSATION MANAGEMENT
  // ========================================

  // Load user conversations and cache other user names
  Future<void> loadUserConversations(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Set current user ID and clear any stale data
      setCurrentUserId(userId);

      // Cancel any existing subscription
      await _conversationsSubscription?.cancel();
      
      // Create new subscription
      _conversationsSubscription = _chatService.getUserConversations(userId).listen((conversations) async {
        try {
          // Check if conversations have changed
          bool conversationsChanged = _conversations.length != conversations.length;
          if (!conversationsChanged) {
            for (int i = 0; i < _conversations.length; i++) {
              if (i < conversations.length && 
                  (_conversations[i].lastMessage != conversations[i].lastMessage ||
                   _conversations[i].lastMessageSenderId != conversations[i].lastMessageSenderId)) {
                conversationsChanged = true;
                break;
              }
            }
          }
          
          if (conversationsChanged) {
            _conversations = conversations;
            
            // Refresh user names cache for new conversations
            await refreshUserNamesCache(userId);
            
            notifyListeners();
          }
        } catch (e) {
          print('DEBUG: Error in conversations stream: $e');
          _setError('Failed to load conversations: $e');
        }
      });
      
    } catch (e) {
      _setError('Failed to load conversations: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get conversation by ID
  Future<ConversationModel?> getConversation(String conversationId) async {
    try {
      _setLoading(true);
      _clearError();

      final conversation = await _chatService.getConversation(conversationId);
      _currentConversation = conversation;
      notifyListeners();
      return conversation;
    } catch (e) {
      _setError('Failed to get conversation: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Create or get conversation between two users
  Future<String?> createOrGetConversation(String user1Id, String user2Id) async {
    try {
      _setLoading(true);
      _clearError();

      final conversationId = await _chatService.createOrGetConversation(user1Id, user2Id);
      return conversationId;
    } catch (e) {
      _setError('Failed to create conversation: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Mark conversation as seen
  Future<void> markConversationAsSeen(String conversationId, String userId) async {
    try {
      await _chatService.markConversationAsSeen(conversationId, userId);
      
      // Update local state
      final index = _conversations.indexWhere((conv) => conv.id == conversationId);
      if (index != -1) {
        final updatedUnseenCount = Map<String, int>.from(_conversations[index].unseenCount);
        updatedUnseenCount[userId] = 0;
        _conversations[index] = _conversations[index].copyWith(unseenCount: updatedUnseenCount);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to mark conversation as seen: $e');
    }
  }

  // ========================================
  // MESSAGE MANAGEMENT
  // ========================================

  // Load messages for a conversation
  Future<void> loadConversationMessages(String conversationId) async {
    try {
      _setLoading(true);
      _clearError();

      // Cancel any existing messages subscription
      await _messagesSubscription?.cancel();
      
      // Create new subscription
      _messagesSubscription = _chatService.getConversationMessages(conversationId).listen((messages) {
        _messages = messages;
        // Use Future.microtask to avoid setState during build
        Future.microtask(() => notifyListeners());
      });
    } catch (e) {
      _setError('Failed to load messages: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Send a message
  Future<bool> sendMessage(String conversationId, String content) async {
    if (content.trim().isEmpty) return false;

    try {
      _setSendingMessage(true);
      _clearError();

      final currentUserId = _getCurrentUserId();
      final conversation = await _chatService.getConversation(conversationId);
      
      if (conversation == null) {
        _setError('Conversation not found');
        return false;
      }

      final receiverId = conversation.getOtherParticipant(currentUserId);
      
      final message = _chatService.createTextMessage(
        senderId: currentUserId,
        receiverId: receiverId,
        content: content.trim(),
      );

      await _chatService.sendMessage(conversationId, message);
      
      // Update local conversation state immediately
      final conversationIndex = _conversations.indexWhere((conv) => conv.id == conversationId);
      if (conversationIndex != -1) {
        final updatedUnseenCount = Map<String, int>.from(_conversations[conversationIndex].unseenCount);
        updatedUnseenCount[receiverId] = (updatedUnseenCount[receiverId] ?? 0) + 1;
        
        _conversations[conversationIndex] = _conversations[conversationIndex].copyWith(
          lastMessage: content.trim(),
          lastMessageTimestamp: DateTime.now(),
          lastMessageSenderId: currentUserId,
          unseenCount: updatedUnseenCount,
        );
        
        // Refresh user names cache for this conversation
        await _refreshUserNamesForConversation(conversationId, currentUserId);
        
        notifyListeners();
      }
      
      // Send notification to the receiver
      await NotificationHelper.notifyNewMessage(
        recipientId: receiverId,
        messagePreview: content.trim(),
        conversationId: conversationId,
        senderId: currentUserId,
      );
      
      return true;
    } catch (e) {
      _setError('Failed to send message: $e');
      return false;
    } finally {
      _setSendingMessage(false);
    }
  }

  // Mark message as seen
  Future<void> markMessageAsSeen(String conversationId, String messageId) async {
    try {
      await _chatService.markMessageAsSeen(conversationId, messageId);
      
      // Update local state
      final index = _messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(seen: true);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to mark message as seen: $e');
    }
  }

  // Mark all messages in conversation as seen
  Future<void> markAllMessagesAsSeen(String conversationId) async {
    try {
      final currentUserId = _getCurrentUserId();
      await _chatService.markAllMessagesAsSeen(conversationId, currentUserId);
      
      // Update local state
      for (int i = 0; i < _messages.length; i++) {
        if (_messages[i].receiverId == currentUserId && !_messages[i].seen) {
          _messages[i] = _messages[i].copyWith(seen: true);
        }
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to mark all messages as seen: $e');
    }
  }

  // Delete a message
  Future<bool> deleteMessage(String conversationId, String messageId) async {
    try {
      await _chatService.deleteMessage(conversationId, messageId);
      
      // Update local state
      _messages.removeWhere((msg) => msg.id == messageId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete message: $e');
      return false;
    }
  }

  // Edit a message
  Future<bool> editMessage(String conversationId, String messageId, String newContent) async {
    if (newContent.trim().isEmpty) return false;

    try {
      await _chatService.editMessage(conversationId, messageId, newContent.trim());
      
      // Update local state
      final index = _messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          content: newContent.trim(),
          edited: true,
          editedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to edit message: $e');
      return false;
    }
  }

  // ========================================
  // CONTACT POSTER FUNCTIONALITY
  // ========================================

  // Handle contact poster button click
  Future<String?> handleContactPoster(String currentUserId, String posterId) async {
    try {
      return await _chatService.handleContactPoster(currentUserId, posterId);
    } catch (e) {
      _setError('Failed to contact poster: $e');
      return null;
    }
  }

  // Load other user data for current conversation
  Future<void> loadOtherUserData(String conversationId, String currentUserId) async {
    try {
      final conversation = await _chatService.getConversation(conversationId);
      if (conversation != null) {
        final otherUserId = conversation.getOtherParticipant(currentUserId);
        final user = await _firestoreService.getUser(otherUserId);
        if (user != null) {
          _otherUser = user;
          notifyListeners();
        }
      }
    } catch (e) {
      _setError('Failed to load other user data: $e');
    }
  }

  // ========================================
  // BLOCK USER FUNCTIONALITY
  // ========================================

  // Check if users are blocked
  Future<void> checkBlockStatus(String currentUserId, String otherUserId) async {
    try {
      final isUserBlocked = await _firestoreService.isUserBlocked(otherUserId, currentUserId);
      final hasBlockedUser = await _firestoreService.isUserBlocked(currentUserId, otherUserId);
      
      _isUserBlocked = isUserBlocked;
      _hasBlockedUser = hasBlockedUser;
      notifyListeners();
    } catch (e) {
      _setError('Failed to check block status: $e');
    }
  }

  // Block a user
  Future<bool> blockUser(String currentUserId, String userToBlockId) async {
    try {
      final success = await _firestoreService.blockUser(currentUserId, userToBlockId);
      if (success) {
        _hasBlockedUser = true;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Failed to block user: $e');
      return false;
    }
  }

  // Unblock a user
  Future<bool> unblockUser(String currentUserId, String userToUnblockId) async {
    try {
      final success = await _firestoreService.unblockUser(currentUserId, userToUnblockId);
      if (success) {
        _hasBlockedUser = false;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Failed to unblock user: $e');
      return false;
    }
  }

  // Check if can send message (not blocked)
  bool canSendMessage() {
    return !_isUserBlocked && !_hasBlockedUser;
  }

  // ========================================
  // SEARCH FUNCTIONALITY
  // ========================================

  // Set search query
  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Clear search query
  void clearSearchQuery() {
    _searchQuery = null;
    notifyListeners();
  }

  // Search conversations
  Future<List<ConversationModel>> searchConversations(String userId, String query) async {
    try {
      return await _chatService.searchConversations(userId, query);
    } catch (e) {
      _setError('Failed to search conversations: $e');
      return [];
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  // Get current user ID (you'll need to inject this or get from auth provider)
  String _getCurrentUserId() {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      throw Exception('Current user ID is not set in ChatProvider. Please call setCurrentUserId before sending messages.');
    }
    return _currentUserId!;
  }

  // Set current user ID (to be called from outside)
  String? _currentUserId;
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  // Clear current user ID
  void clearCurrentUserId() {
    _currentUserId = null;
  }

  // Get current user ID (updated method)
  String getCurrentUserId() {
    return _currentUserId ?? '';
  }

  // Clear current conversation
  void clearCurrentConversation() {
    _currentConversation = null;
    _otherUser = null;
    _messages.clear();
    _isUserBlocked = false;
    _hasBlockedUser = false;
    notifyListeners();
  }

  // Clear all data and cancel subscriptions
  Future<void> _clearAllDataAndSubscriptions() async {
    print('DEBUG: ChatProvider._clearAllDataAndSubscriptions called');
    
    // Cancel existing subscriptions
    await _conversationsSubscription?.cancel();
    await _messagesSubscription?.cancel();
    
    // Clear data
    _conversations.clear();
    _messages.clear();
    _currentConversation = null;
    _otherUser = null;
    _searchQuery = null;
    _isUserBlocked = false;
    _hasBlockedUser = false;
    _conversationUserNames.clear(); // Clear the user name cache
    clearCurrentUserId(); // Clear current user ID
    
    print('DEBUG: ChatProvider._clearAllDataAndSubscriptions completed - cache cleared');
    notifyListeners();
  }

  // Clear all data (public method for backward compatibility)
  void clearAllData() {
    print('DEBUG: ChatProvider.clearAllData called');
    _clearAllDataAndSubscriptions();
  }

  // Get unread message count for a specific conversation
  int getUnreadCountForConversation(String conversationId) {
    final conversation = _conversations.firstWhere(
      (conv) => conv.id == conversationId,
      orElse: () => ConversationModel(
        id: '',
        participants: [],
        lastMessage: '',
        lastMessageTimestamp: DateTime.now(),
        lastMessageSenderId: '',
        unseenCount: {},
      ),
    );
    return conversation.getUnreadCount(_getCurrentUserId());
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  void _setLoading(bool loading) {
    _isLoading = loading;
    Future.microtask(() => notifyListeners());
  }

  void _setSendingMessage(bool sending) {
    _isSendingMessage = sending;
    Future.microtask(() => notifyListeners());
  }

  void _setError(String? error) {
    _errorMessage = error;
    Future.microtask(() => notifyListeners());
    
    // Auto-clear temporary errors
    if (error != null && 
        (error.contains('Concurrent modification') || 
         error.contains('Failed to refresh user names'))) {
      _clearErrorAfterDelay();
    }
  }

  void _clearError() {
    _errorMessage = null;
    Future.microtask(() => notifyListeners());
  }

  // Clear error after a delay (for temporary errors)
  void _clearErrorAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_errorMessage != null && 
          (_errorMessage!.contains('Concurrent modification') || 
           _errorMessage!.contains('Failed to refresh user names'))) {
        _clearError();
      }
    });
  }

  // Clear error message
  void clearError() {
    _clearError();
  }

  // Delete a conversation and all its messages
  Future<bool> deleteConversation(String conversationId) async {
    try {
      await _chatService.deleteConversation(conversationId);
      _conversations.removeWhere((conv) => conv.id == conversationId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete conversation: $e');
      return false;
    }
  }

  // Batch delete messages in a conversation
  Future<bool> deleteMessages(String conversationId, List<String> messageIds) async {
    try {
      await _chatService.deleteMessages(conversationId, messageIds);
      _messages.removeWhere((msg) => messageIds.contains(msg.id));
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete messages: $e');
      return false;
    }
  }

  @override
  void dispose() {
    // Cancel all subscriptions when provider is disposed
    _conversationsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
} 