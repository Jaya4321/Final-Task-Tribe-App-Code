import 'package:cloud_firestore/cloud_firestore.dart';

class TaskApplicationModel {
  final String id;
  final String taskId;
  final String applicantId;
  final String message;
  final DateTime appliedAt;
  final bool isAccepted;
  final DateTime? acceptedAt;
  final String? acceptedBy;

  TaskApplicationModel({
    required this.id,
    required this.taskId,
    required this.applicantId,
    required this.message,
    required this.appliedAt,
    this.isAccepted = false,
    this.acceptedAt,
    this.acceptedBy,
  });

  factory TaskApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskApplicationModel(
      id: doc.id,
      taskId: data['taskId'] ?? '',
      applicantId: data['applicantId'] ?? '',
      message: data['message'] ?? '',
      appliedAt: (data['appliedAt'] as Timestamp).toDate(),
      isAccepted: data['isAccepted'] ?? false,
      acceptedAt: data['acceptedAt'] != null 
          ? (data['acceptedAt'] as Timestamp).toDate() 
          : null,
      acceptedBy: data['acceptedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'applicantId': applicantId,
      'message': message,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'isAccepted': isAccepted,
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'acceptedBy': acceptedBy,
    };
  }

  TaskApplicationModel copyWith({
    String? id,
    String? taskId,
    String? applicantId,
    String? message,
    DateTime? appliedAt,
    bool? isAccepted,
    DateTime? acceptedAt,
    String? acceptedBy,
  }) {
    return TaskApplicationModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      applicantId: applicantId ?? this.applicantId,
      message: message ?? this.message,
      appliedAt: appliedAt ?? this.appliedAt,
      isAccepted: isAccepted ?? this.isAccepted,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      acceptedBy: acceptedBy ?? this.acceptedBy,
    );
  }

  @override
  String toString() {
    return 'TaskApplicationModel(id: $id, taskId: $taskId, applicantId: $applicantId, isAccepted: $isAccepted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskApplicationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 