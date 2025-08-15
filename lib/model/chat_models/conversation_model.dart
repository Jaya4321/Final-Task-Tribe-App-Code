import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTimestamp;
  final String lastMessageSenderId;
  final Map<String, int> unseenCount;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTimestamp,
    required this.lastMessageSenderId,
    required this.unseenCount,
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTimestamp: (data['lastMessageTimestamp'] as Timestamp).toDate(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      unseenCount: Map<String, int>.from(data['unseenCount'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': Timestamp.fromDate(lastMessageTimestamp),
      'lastMessageSenderId': lastMessageSenderId,
      'unseenCount': unseenCount,
    };
  }

  ConversationModel copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTimestamp,
    String? lastMessageSenderId,
    Map<String, int>? unseenCount,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unseenCount: unseenCount ?? this.unseenCount,
    );
  }

  // Get the other participant in the conversation
  String getOtherParticipant(String currentUserId) {
    return participants.firstWhere((participant) => participant != currentUserId);
  }

  // Check if user is a participant
  bool isParticipant(String userId) {
    return participants.contains(userId);
  }

  // Get unread count for a specific user
  int getUnreadCount(String userId) {
    return unseenCount[userId] ?? 0;
  }

  // Check if conversation has unread messages for a user
  bool hasUnreadMessages(String userId) {
    return getUnreadCount(userId) > 0;
  }

  @override
  String toString() {
    return 'ConversationModel(id: $id, participants: $participants, lastMessage: $lastMessage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 