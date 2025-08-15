import 'package:cloud_firestore/cloud_firestore.dart';

class TaskReviewModel {
  final String id;
  final String taskId;
  final String reviewerId;
  final String reviewedUserId;
  final double rating;
  final String reviewText;
  final DateTime reviewedAt;
  final Map<String, double> categoryRatings;

  TaskReviewModel({
    required this.id,
    required this.taskId,
    required this.reviewerId,
    required this.reviewedUserId,
    required this.rating,
    required this.reviewText,
    required this.reviewedAt,
    this.categoryRatings = const {},
  });

  factory TaskReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskReviewModel(
      id: doc.id,
      taskId: data['taskId'] ?? '',
      reviewerId: data['reviewerId'] ?? '',
      reviewedUserId: data['reviewedUserId'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      reviewText: data['reviewText'] ?? '',
      reviewedAt: (data['reviewedAt'] as Timestamp).toDate(),
      categoryRatings: Map<String, double>.from(data['categoryRatings'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'reviewerId': reviewerId,
      'reviewedUserId': reviewedUserId,
      'rating': rating,
      'reviewText': reviewText,
      'reviewedAt': Timestamp.fromDate(reviewedAt),
      'categoryRatings': categoryRatings,
    };
  }

  TaskReviewModel copyWith({
    String? id,
    String? taskId,
    String? reviewerId,
    String? reviewedUserId,
    double? rating,
    String? reviewText,
    DateTime? reviewedAt,
    Map<String, double>? categoryRatings,
  }) {
    return TaskReviewModel(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewedUserId: reviewedUserId ?? this.reviewedUserId,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      categoryRatings: categoryRatings ?? this.categoryRatings,
    );
  }

  // Validation methods
  bool get isValid {
    return taskId.isNotEmpty &&
        reviewerId.isNotEmpty &&
        reviewedUserId.isNotEmpty &&
        rating >= 1.0 &&
        rating <= 5.0 &&
        reviewText.isNotEmpty &&
        reviewText.length <= 500;
  }

  @override
  String toString() {
    return 'TaskReviewModel(id: $id, taskId: $taskId, rating: $rating, reviewerId: $reviewerId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskReviewModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 