import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  voice,
  file,
}

class ChatMessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final bool seen;
  final bool edited;
  final DateTime? editedAt;

  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.type,
    required this.content,
    required this.timestamp,
    this.seen = false,
    this.edited = false,
    this.editedAt,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      type: _parseMessageType(data['type'] ?? 'text'),
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      seen: data['seen'] ?? false,
      edited: data['edited'] ?? false,
      editedAt: data['editedAt'] != null 
          ? (data['editedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'type': type.name,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'seen': seen,
      'edited': edited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
    };
  }

  ChatMessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    MessageType? type,
    String? content,
    DateTime? timestamp,
    bool? seen,
    bool? edited,
    DateTime? editedAt,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      seen: seen ?? this.seen,
      edited: edited ?? this.edited,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  // Check if message is from current user
  bool isFromUser(String userId) {
    return senderId == userId;
  }

  // Check if message is to current user
  bool isToUser(String userId) {
    return receiverId == userId;
  }

  // Get formatted timestamp
  String getFormattedTime() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inHours > 0) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Check if message is recent (within last 24 hours)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inHours < 24;
  }

  // Validation methods
  bool get isValid {
    return senderId.isNotEmpty &&
        receiverId.isNotEmpty &&
        content.isNotEmpty &&
        content.length <= 1000 &&
        senderId != receiverId;
  }

  static MessageType _parseMessageType(String type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'voice':
        return MessageType.voice;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }

  @override
  String toString() {
    return 'ChatMessageModel(id: $id, senderId: $senderId, content: $content, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 