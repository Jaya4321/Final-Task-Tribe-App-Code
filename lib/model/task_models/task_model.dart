import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  open,
  assigned,
  delivered,
  completed,
  cancelled,
}

enum MutualStatus {
  pending,
  accepted,
  rejected,
  completed,
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String date;
  final String time;
  final String location;
  final double reward;
  final String? additionalRequirements;
  final TaskStatus status;
  final DateTime createdAt;

  // Relations
  final String posterId;
  final String? doerId;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  // Applicants
  final List<Map<String, dynamic>> applicants;

  // Delivery Proof
  final Map<String, dynamic> deliveryProof;

  // Ratings
  final double? ratingByPoster;
  final double? ratingByDoer;
  final String? reviewMessageByPoster;
  final String? reviewMessageByDoer;

  // NEW: Mutual Tasking Fields
  final bool isMutual;
  final String? mutualOfferTaskId;
  final String? mutualPartnerUserId;
  final MutualStatus? mutualStatus;

  // Add this field to TaskModel
  final List<MutualProposal> mutualProposals;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    required this.time,
    required this.location,
    required this.reward,
    this.additionalRequirements,
    required this.status,
    required this.createdAt,
    required this.posterId,
    this.doerId,
    this.acceptedAt,
    this.completedAt,
    this.applicants = const [],
    this.deliveryProof = const {},
    this.ratingByPoster,
    this.ratingByDoer,
    this.reviewMessageByPoster,
    this.reviewMessageByDoer,
    this.isMutual = false,
    this.mutualOfferTaskId,
    this.mutualPartnerUserId,
    this.mutualStatus,
    this.mutualProposals = const [],
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      location: data['location'] ?? '',
      reward: (data['reward'] ?? 0).toDouble(),
      additionalRequirements: data['additionalRequirements'],
      status: _parseTaskStatus(data['status'] ?? 'open'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      posterId: data['posterId'] ?? '',
      doerId: data['doerId'],
      acceptedAt: data['acceptedAt'] != null 
          ? (data['acceptedAt'] as Timestamp).toDate() 
          : null,
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null,
      applicants: List<Map<String, dynamic>>.from(data['applicants'] ?? []),
      deliveryProof: Map<String, dynamic>.from(data['deliveryProof'] ?? {}),
      ratingByPoster: data['ratingByPoster']?.toDouble(),
      ratingByDoer: data['ratingByDoer']?.toDouble(),
      reviewMessageByPoster: data['reviewMessageByPoster'],
      reviewMessageByDoer: data['reviewMessageByDoer'],
      isMutual: data['isMutual'] ?? false,
      mutualOfferTaskId: data['mutualOfferTaskId'],
      mutualPartnerUserId: data['mutualPartnerUserId'],
      mutualStatus: _parseMutualStatus(data['mutualStatus']),
      mutualProposals: (data['mutualProposals'] as List<dynamic>? ?? [])
        .map((e) => MutualProposal.fromMap(Map<String, dynamic>.from(e)))
        .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'date': date,
      'time': time,
      'location': location,
      'reward': reward,
      'additionalRequirements': additionalRequirements,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'posterId': posterId,
      'doerId': doerId,
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'applicants': applicants,
      'deliveryProof': deliveryProof,
      'ratingByPoster': ratingByPoster,
      'ratingByDoer': ratingByDoer,
      'reviewMessageByPoster': reviewMessageByPoster,
      'reviewMessageByDoer': reviewMessageByDoer,
      'isMutual': isMutual,
      'mutualOfferTaskId': mutualOfferTaskId,
      'mutualPartnerUserId': mutualPartnerUserId,
      'mutualStatus': mutualStatus?.name,
      'mutualProposals': mutualProposals.map((e) => e.toMap()).toList(),
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? date,
    String? time,
    String? location,
    double? reward,
    String? additionalRequirements,
    TaskStatus? status,
    DateTime? createdAt,
    String? posterId,
    String? doerId,
    DateTime? acceptedAt,
    DateTime? completedAt,
    List<Map<String, dynamic>>? applicants,
    Map<String, dynamic>? deliveryProof,
    double? ratingByPoster,
    double? ratingByDoer,
    String? reviewMessageByPoster,
    String? reviewMessageByDoer,
    bool? isMutual,
    String? mutualOfferTaskId,
    String? mutualPartnerUserId,
    MutualStatus? mutualStatus,
    List<MutualProposal>? mutualProposals,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      reward: reward ?? this.reward,
      additionalRequirements: additionalRequirements ?? this.additionalRequirements,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      posterId: posterId ?? this.posterId,
      doerId: doerId ?? this.doerId,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      applicants: applicants ?? this.applicants,
      deliveryProof: deliveryProof ?? this.deliveryProof,
      ratingByPoster: ratingByPoster ?? this.ratingByPoster,
      ratingByDoer: ratingByDoer ?? this.ratingByDoer,
      reviewMessageByPoster: reviewMessageByPoster ?? this.reviewMessageByPoster,
      reviewMessageByDoer: reviewMessageByDoer ?? this.reviewMessageByDoer,
      isMutual: isMutual ?? this.isMutual,
      mutualOfferTaskId: mutualOfferTaskId ?? this.mutualOfferTaskId,
      mutualPartnerUserId: mutualPartnerUserId ?? this.mutualPartnerUserId,
      mutualStatus: mutualStatus ?? this.mutualStatus,
      mutualProposals: mutualProposals ?? this.mutualProposals,
    );
  }

  // Helper methods for status checking
  bool get isOpen => status == TaskStatus.open;
  bool get isAssigned => status == TaskStatus.assigned;
  bool get isDelivered => status == TaskStatus.delivered;
  bool get isCompleted => status == TaskStatus.completed;
  bool get isCancelled => status == TaskStatus.cancelled;

  // Helper methods for user permissions
  bool isPoster(String userId) => posterId == userId;
  bool isDoer(String userId) => doerId == userId;
  bool canEdit(String userId) => isPoster(userId) && isOpen;
  bool canCancel(String userId) => isPoster(userId) && isOpen;
  bool canDelete(String userId) => isPoster(userId) && isOpen && doerId == null;
  bool canApply(String userId) => !isPoster(userId) && isOpen;
  bool canAccept(String userId) => isPoster(userId) && isOpen && applicants.isNotEmpty;

  // NEW: Mutual task helper methods
  bool get isMutualTask => isMutual;
  bool hasPendingMutualProposals() => mutualProposals.any((p) => p.status == MutualStatus.pending);
  bool get isMutualAccepted => mutualStatus == MutualStatus.accepted;
  bool get isMutualCompleted => mutualStatus == MutualStatus.completed;
  bool get isMutualRejected => mutualStatus == MutualStatus.rejected;
  
  bool canProposeMutual(String userId) => !isPoster(userId) && isOpen && isMutual && 
      !mutualProposals.any((p) => p.proposerUserId == userId && p.status == MutualStatus.pending);
  
  // NEW: Check if user can propose with a specific mutual task
  bool canProposeWithTask(String userId, String offeredTaskId) {
    // Check if user has already proposed with this specific task and it was rejected
    return !mutualProposals.any((p) => 
        p.proposerUserId == userId && 
        p.offeredTaskId == offeredTaskId && 
        p.status == MutualStatus.rejected);
  }
  
  // NEW: Check if user has any available tasks to propose with
  bool hasAvailableTasksToPropose(String userId, List<TaskModel> userTasks) {
    // Check if user has any tasks that haven't been rejected for this target task
    return userTasks.any((task) => canProposeWithTask(userId, task.id));
  }
  bool canAcceptMutual(String userId) => isPoster(userId) && isOpen && isMutual && hasPendingMutualProposals();
  bool canRejectMutual(String userId) => isPoster(userId) && isOpen && isMutual && hasPendingMutualProposals();

  // Helper methods for applicant management
  bool hasApplied(String userId) {
    return applicants.any((applicant) => applicant['userId'] == userId);
  }

  int getApplicantCount() {
    return applicants.length;
  }

  // Get applicant data for a specific user
  Map<String, dynamic>? getApplicantData(String userId) {
    try {
      return applicants.firstWhere((applicant) => applicant['userId'] == userId);
    } catch (e) {
      return null;
    }
  }

  // Get application message for a specific user
  String? getApplicationMessage(String userId) {
    final applicantData = getApplicantData(userId);
    return applicantData?['message'];
  }

  // Get application timestamp for a specific user
  DateTime? getApplicationTimestamp(String userId) {
    final applicantData = getApplicantData(userId);
    if (applicantData != null && applicantData['appliedAt'] != null) {
      return (applicantData['appliedAt'] as Timestamp).toDate();
    }
    return null;
  }

  // Review helper methods
  bool get hasPosterReview => ratingByPoster != null && reviewMessageByPoster != null;
  bool get hasDoerReview => ratingByDoer != null && reviewMessageByDoer != null;
  bool get bothReviewsSubmitted => hasPosterReview && hasDoerReview;
  bool get canShowReviews => bothReviewsSubmitted;

  // Validation methods
  bool get isValid {
    return title.isNotEmpty &&
        description.isNotEmpty &&
        category.isNotEmpty &&
        date.isNotEmpty &&
        time.isNotEmpty &&
        location.isNotEmpty &&
        (isMutual || reward > 0) && // Allow 0 reward for mutual tasks
        posterId.isNotEmpty;
  }

  // --- Mutual Proposal Helpers ---
  List<MutualProposal> getPendingMutualProposals() => mutualProposals.where((p) => p.status == MutualStatus.pending).toList();
  List<MutualProposal> getRejectedMutualProposals() => mutualProposals.where((p) => p.status == MutualStatus.rejected).toList();
  
  MutualProposal? getAcceptedMutualProposal() {
    try {
      return mutualProposals.firstWhere((p) => p.status == MutualStatus.accepted);
    } catch (_) {
      return null;
    }
  }
  
  // Check if user has a specific proposal status
  bool hasUserProposalWithStatus(String userId, MutualStatus status) {
    return mutualProposals.any((p) => p.proposerUserId == userId && p.status == status);
  }
  
  // Get user's proposal status for this task
  MutualStatus? getUserProposalStatus(String userId) {
    try {
      final proposal = mutualProposals.firstWhere((p) => p.proposerUserId == userId);
      return proposal.status;
    } catch (_) {
      return null;
    }
  }

  static TaskStatus _parseTaskStatus(String status) {
    switch (status) {
      case 'open':
        return TaskStatus.open;
      case 'assigned':
        return TaskStatus.assigned;
      case 'delivered':
        return TaskStatus.delivered;
      case 'completed':
        return TaskStatus.completed;
      case 'cancelled':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.open;
    }
  }

  static MutualStatus? _parseMutualStatus(String? status) {
    if (status == null) return null;
    switch (status) {
      case 'pending':
        return MutualStatus.pending;
      case 'accepted':
        return MutualStatus.accepted;
      case 'rejected':
        return MutualStatus.rejected;
      case 'completed':
        return MutualStatus.completed;
      default:
        return null;
    }
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, title: $title, status: $status, posterId: $posterId, isMutual: $isMutual)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// --- Mutual Proposal Model ---
class MutualProposal {
  final String proposerUserId;
  final String offeredTaskId;
  final DateTime proposedAt;
  final MutualStatus status; // pending, accepted, rejected

  MutualProposal({
    required this.proposerUserId,
    required this.offeredTaskId,
    required this.proposedAt,
    this.status = MutualStatus.pending,
  });

  factory MutualProposal.fromMap(Map<String, dynamic> map) {
    return MutualProposal(
      proposerUserId: map['proposerUserId'],
      offeredTaskId: map['offeredTaskId'],
      proposedAt: (map['proposedAt'] as Timestamp).toDate(),
      status: TaskModel._parseMutualStatus(map['status']) ?? MutualStatus.pending,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'proposerUserId': proposerUserId,
      'offeredTaskId': offeredTaskId,
      'proposedAt': Timestamp.fromDate(proposedAt),
      'status': status.name,
    };
  }

  MutualProposal copyWith({
    String? proposerUserId,
    String? offeredTaskId,
    DateTime? proposedAt,
    MutualStatus? status,
  }) {
    return MutualProposal(
      proposerUserId: proposerUserId ?? this.proposerUserId,
      offeredTaskId: offeredTaskId ?? this.offeredTaskId,
      proposedAt: proposedAt ?? this.proposedAt,
      status: status ?? this.status,
    );
  }
} 