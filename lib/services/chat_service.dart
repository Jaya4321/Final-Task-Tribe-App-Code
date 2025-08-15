import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/chat_models/chat_message_model.dart';
import '../model/chat_models/conversation_model.dart';
import 'firestore_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Collection references
  CollectionReference get _conversationsCollection => _firestore.collection('conversations');

  // ========================================
  // CONVERSATION MANAGEMENT
  // ========================================

  // Create or get existing conversation between two users
  Future<String> createOrGetConversation(String user1Id, String user2Id) async {
    try {
      // Check if users are blocked
      final areBlocked = await _firestoreService.areUsersBlocked(user1Id, user2Id);
      if (areBlocked) {
        throw Exception('Cannot create conversation with blocked user');
      }

      // Create conversation ID with sorted UIDs for consistency
      final List<String> participants = [user1Id, user2Id];
      participants.sort(); // Ensure alphabetical order
      final conversationId = '${participants[0]}_${participants[1]}';

      // Check if conversation already exists
      final existingDoc = await _conversationsCollection.doc(conversationId).get();
      
      if (!existingDoc.exists) {
        // Create new conversation
        final conversation = ConversationModel(
          id: conversationId,
          participants: participants,
          lastMessage: '',
          lastMessageTimestamp: DateTime.now(),
          lastMessageSenderId: '',
          unseenCount: {user1Id: 0, user2Id: 0},
        );

        await _conversationsCollection.doc(conversationId).set(conversation.toMap());
      }

      return conversationId;
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  // Get all conversations for a user
  Stream<List<ConversationModel>> getUserConversations(String userId) {
    return _conversationsCollection
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConversationModel.fromFirestore(doc))
            .toList());
  }

  // Get single conversation
  Future<ConversationModel?> getConversation(String conversationId) async {
    try {
      final doc = await _conversationsCollection.doc(conversationId).get();
      if (doc.exists) {
        return ConversationModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get conversation: $e');
    }
  }

  // Update conversation (last message, unseen count)
  Future<void> updateConversation(String conversationId, {
    String? lastMessage,
    String? lastMessageSenderId,
    Map<String, int>? unseenCount,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (lastMessage != null) {
        updateData['lastMessage'] = lastMessage;
        updateData['lastMessageTimestamp'] = Timestamp.fromDate(DateTime.now());
      }
      
      if (lastMessageSenderId != null) {
        updateData['lastMessageSenderId'] = lastMessageSenderId;
      }
      
      if (unseenCount != null) {
        updateData['unseenCount'] = unseenCount;
      }

      await _conversationsCollection.doc(conversationId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update conversation: $e');
    }
  }

  // Mark conversation as seen for a user
  Future<void> markConversationAsSeen(String conversationId, String userId) async {
    try {
      final conversation = await getConversation(conversationId);
      if (conversation != null) {
        final updatedUnseenCount = Map<String, int>.from(conversation.unseenCount);
        updatedUnseenCount[userId] = 0;
        
        await updateConversation(conversationId, unseenCount: updatedUnseenCount);
      }
    } catch (e) {
      throw Exception('Failed to mark conversation as seen: $e');
    }
  }

  // ========================================
  // MESSAGE MANAGEMENT
  // ========================================

  // Send a message
  Future<void> sendMessage(String conversationId, ChatMessageModel message) async {
    try {
      // Check if users are blocked before sending message
      final areBlocked = await _firestoreService.areUsersBlocked(message.senderId, message.receiverId);
      if (areBlocked) {
        throw Exception('Cannot send message to blocked user');
      }

      // Add message to subcollection
      await _conversationsCollection
          .doc(conversationId)
          .collection('messages')
          .add(message.toMap());

      // Update conversation with last message info
      final conversation = await getConversation(conversationId);
      if (conversation != null) {
        final updatedUnseenCount = Map<String, int>.from(conversation.unseenCount);
        // Increment unseen count for receiver
        updatedUnseenCount[message.receiverId] = (updatedUnseenCount[message.receiverId] ?? 0) + 1;
        
        await updateConversation(
          conversationId,
          lastMessage: message.content,
          lastMessageSenderId: message.senderId,
          unseenCount: updatedUnseenCount,
        );
      }
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages for a conversation
  Stream<List<ChatMessageModel>> getConversationMessages(String conversationId) {
    return _conversationsCollection
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(50) // Limit to last 50 messages for performance
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromFirestore(doc))
            .toList());
  }

  // Mark message as seen
  Future<void> markMessageAsSeen(String conversationId, String messageId) async {
    try {
      await _conversationsCollection
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({'seen': true});
    } catch (e) {
      throw Exception('Failed to mark message as seen: $e');
    }
  }

  // Delete a message
  Future<void> deleteMessage(String conversationId, String messageId) async {
    try {
      await _conversationsCollection
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // Edit a message
  Future<void> editMessage(String conversationId, String messageId, String newContent) async {
    try {
      await _conversationsCollection
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
        'content': newContent,
        'edited': true,
        'editedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  // ========================================
  // UTILITY METHODS
  // ========================================

  // Get conversation ID for two users
  String getConversationId(String user1Id, String user2Id) {
    final List<String> participants = [user1Id, user2Id];
    participants.sort();
    return '${participants[0]}_${participants[1]}';
  }

  // Check if conversation exists
  Future<bool> conversationExists(String user1Id, String user2Id) async {
    final conversationId = getConversationId(user1Id, user2Id);
    final doc = await _conversationsCollection.doc(conversationId).get();
    return doc.exists;
  }

  // Get unread message count for a user
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final conversations = await _conversationsCollection
          .where('participants', arrayContains: userId)
          .get();
      
      int totalUnread = 0;
      for (final doc in conversations.docs) {
        final conversation = ConversationModel.fromFirestore(doc);
        totalUnread += conversation.unseenCount[userId] ?? 0;
      }
      
      return totalUnread;
    } catch (e) {
      throw Exception('Failed to get unread message count: $e');
    }
  }

  // Search conversations by user name (requires additional user data)
  Future<List<ConversationModel>> searchConversations(String userId, String searchQuery) async {
    try {
      // This is a basic implementation
      // For better search, you might want to use Algolia or similar service
      final conversations = await _conversationsCollection
          .where('participants', arrayContains: userId)
          .get();
      
      return conversations.docs
          .map((doc) => ConversationModel.fromFirestore(doc))
          .where((conversation) => 
              conversation.lastMessage.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search conversations: $e');
    }
  }

  // ========================================
  // REAL-TIME LISTENERS
  // ========================================

  // Listen to conversation updates
  Stream<ConversationModel?> getConversationStream(String conversationId) {
    return _conversationsCollection
        .doc(conversationId)
        .snapshots()
        .map((doc) => doc.exists ? ConversationModel.fromFirestore(doc) : null);
  }

  // Listen to new messages in a conversation
  Stream<List<ChatMessageModel>> getNewMessagesStream(String conversationId) {
    return _conversationsCollection
        .doc(conversationId)
        .collection('messages')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessageModel.fromFirestore(doc))
            .toList());
  }

  // ========================================
  // CONTACT POSTER FUNCTIONALITY
  // ========================================

  // Handle contact poster button click
  Future<String> handleContactPoster(String currentUserId, String posterId) async {
    try {
      // Check if users are blocked
      final areBlocked = await _firestoreService.areUsersBlocked(currentUserId, posterId);
      if (areBlocked) {
        throw Exception('Cannot contact blocked user');
      }

      // Check if conversation already exists
      final conversationId = getConversationId(currentUserId, posterId);
      final exists = await conversationExists(currentUserId, posterId);
      
      if (exists) {
        // Return existing conversation ID
        return conversationId;
      } else {
        // Create new conversation and return ID
        return await createOrGetConversation(currentUserId, posterId);
      }
    } catch (e) {
      throw Exception('Failed to handle contact poster: $e');
    }
  }

  // Create a text message
  ChatMessageModel createTextMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) {
    return ChatMessageModel(
      id: '', // Will be set by Firestore
      senderId: senderId,
      receiverId: receiverId,
      type: MessageType.text,
      content: content,
      timestamp: DateTime.now(),
      seen: false,
    );
  }

  // ========================================
  // BATCH OPERATIONS
  // ========================================

  // Mark all messages in conversation as seen
  Future<void> markAllMessagesAsSeen(String conversationId, String userId) async {
    try {
      final messages = await _conversationsCollection
          .doc(conversationId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('seen', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in messages.docs) {
        batch.update(doc.reference, {'seen': true});
      }
      await batch.commit();

      // Update conversation unseen count
      await markConversationAsSeen(conversationId, userId);
    } catch (e) {
      throw Exception('Failed to mark all messages as seen: $e');
    }
  }

  // Delete a conversation and all its messages
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Delete all messages in the conversation
      final messagesSnapshot = await _conversationsCollection
          .doc(conversationId)
          .collection('messages')
          .get();
      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      // Delete the conversation document itself
      batch.delete(_conversationsCollection.doc(conversationId));
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  // Batch delete messages in a conversation
  Future<void> deleteMessages(String conversationId, List<String> messageIds) async {
    try {
      final batch = _firestore.batch();
      for (final messageId in messageIds) {
        final ref = _conversationsCollection
            .doc(conversationId)
            .collection('messages')
            .doc(messageId);
        batch.delete(ref);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete messages: $e');
    }
  }
} 