import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/task_models/task_model.dart';
import '../model/task_models/task_application_model.dart';
import '../model/task_models/task_review_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _tasksCollection => _firestore.collection('tasks');
  CollectionReference get _applicationsCollection => _firestore.collection('task_applications');
  CollectionReference get _reviewsCollection => _firestore.collection('task_reviews');

  // Create task
  Future<TaskModel?> createTask(TaskModel task) async {
    try {
      final docRef = await _tasksCollection.add(task.toMap());
      return task.copyWith(id: docRef.id);
    } catch (e) {
      print('Error creating task: $e');
      return null;
    }
  }

  // Get tasks with filtering
  Future<List<TaskModel>> getTasks({
    String? category,
    TaskStatus? status,
    String? searchQuery,
    bool? isMutual,
  }) async {
    try {
      Query query = _tasksCollection;

      // Apply filters
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (isMutual != null) {
        query = query.where('isMutual', isEqualTo: isMutual);
      }

      // Execute the query without orderBy to avoid composite index requirement
      final querySnapshot = await query.get();
      
      // Parse the tasks
      List<TaskModel> tasks = querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
      
      // Apply search query in memory if needed
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        tasks = tasks.where((task) =>
            task.title.toLowerCase().contains(query) ||
            task.description.toLowerCase().contains(query) ||
            task.location.toLowerCase().contains(query)).toList();
      }

      // Sort by createdAt in memory
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return tasks;
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }

  // Get user tasks with mutual filtering
  Future<List<TaskModel>> getUserTasks(String userId, {TaskStatus? status, bool? isMutual}) async {
    try {
      Query query = _tasksCollection.where('posterId', isEqualTo: userId);

      if (isMutual != null) {
        query = query.where('isMutual', isEqualTo: isMutual);
      }

      // Execute the query without orderBy to avoid composite index requirement
      final querySnapshot = await query.get();
      
      // Parse the tasks
      List<TaskModel> tasks = querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
      
      // Apply status filter in memory if needed
      if (status != null) {
        tasks = tasks.where((task) => task.status == status).toList();
      }

      // Sort by createdAt in memory
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return tasks;
    } catch (e) {
      print('Error getting user tasks: $e');
      return [];
    }
  }

  // Get tasks accepted by user
  Future<List<TaskModel>> getAcceptedTasks(String userId, {TaskStatus? status}) async {
    try {
      print('Debug: TaskService.getAcceptedTasks called for userId: $userId');
      print('Debug: Status filter: $status');
      
      // Use a simple approach: get all tasks and filter in memory
      // This avoids any index requirements
      print('Debug: Getting all tasks and filtering in memory...');
      final allTasks = await _getAllTasks();
      print('Debug: Got ${allTasks.length} total tasks');
      
      // Filter tasks where the user is the doer
      List<TaskModel> tasks = allTasks.where((task) => task.doerId == userId).toList();
      print('Debug: Found ${tasks.length} tasks where user is doer');
      
      // Apply status filter in memory if needed
      if (status != null) {
        print('Debug: Applying status filter: ${status.name}');
        tasks = tasks.where((task) => task.status == status).toList();
        print('Debug: After status filter: ${tasks.length} tasks');
      }
      
      // Sort by createdAt in memory
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      print('Debug: Final result: ${tasks.length} accepted tasks');
      
      return tasks;
    } catch (e) {
      print('Error getting accepted tasks: $e');
      return [];
    }
  }

  // Helper method to get all tasks (for fallback)
  Future<List<TaskModel>> _getAllTasks() async {
    try {
      final querySnapshot = await _tasksCollection.get();
      return querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting all tasks: $e');
      return [];
    }
  }

  // Get single task
  Future<TaskModel?> getTask(String taskId) async {
    try {
      final doc = await _tasksCollection.doc(taskId).get();
      if (doc.exists) {
        return TaskModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting task: $e');
      return null;
    }
  }

  // Update task status
  Future<bool> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      final Map<String, dynamic> updateData = {'status': status.name};
      
      if (status == TaskStatus.assigned) {
        updateData['acceptedAt'] = Timestamp.fromDate(DateTime.now());
      } else if (status == TaskStatus.completed) {
        updateData['completedAt'] = Timestamp.fromDate(DateTime.now());
      }

      await _tasksCollection.doc(taskId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating task status: $e');
      return false;
    }
  }

  // Apply for task
  Future<bool> applyForTask(String taskId, String userId) async {
    try {
      // Check if user has already applied
      final task = await getTask(taskId);
      if (task != null && task.hasApplied(userId)) {
        print('User has already applied for this task');
        return false;
      }

      // Add applicant to task's applicants list with message
      await _tasksCollection.doc(taskId).update({
        'applicants': FieldValue.arrayUnion([
          {
            'userId': userId,
            'appliedAt': Timestamp.fromDate(DateTime.now()),
          }
        ])
      });

      return true;
    } catch (e) {
      print('Error applying for task: $e');
      return false;
    }
  }

  // Get task applicants (from task document)
  Future<List<Map<String, dynamic>>> getTaskApplicants(String taskId) async {
    try {
      final task = await getTask(taskId);
      if (task != null) {
        return task.applicants;
      }
      return [];
    } catch (e) {
      print('Error getting task applicants: $e');
      return [];
    }
  }

  // Hire an applicant
  Future<bool> hireApplicant(String taskId, String applicantId) async {
    try {
      // Update task to assign the applicant as doer
      await _tasksCollection.doc(taskId).update({
        'doerId': applicantId,
        'status': TaskStatus.assigned.name,
        'acceptedAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error hiring applicant: $e');
      return false;
    }
  }

  // Deliver task
  Future<bool> deliverTask(String taskId, String message, String? imageUrl) async {
    try {
      final now = DateTime.now();
      final Map<String, dynamic> deliveryProofData = {
        'type': imageUrl != null ? 'image' : 'text',
        'url': imageUrl,
        'uploadedAt': Timestamp.fromDate(now),
        'message': message,
      };

      final Map<String, dynamic> updateData = {
        'status': TaskStatus.delivered.name,
        'deliveryProof': deliveryProofData,
      };

      await _tasksCollection.doc(taskId).update(updateData);
      return true;
    } catch (e) {
      print('Error delivering task: $e');
      return false;
    }
  }

  // Accept delivery
  Future<bool> acceptDelivery(String taskId) async {
    try {
      await _tasksCollection.doc(taskId).update({
        'status': TaskStatus.completed.name,
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error accepting delivery: $e');
      return false;
    }
  }

  // Reject delivery
  Future<bool> rejectDelivery(String taskId) async {
    try {
      await _tasksCollection.doc(taskId).update({
        'status': TaskStatus.assigned.name, // Back to assigned status
      });
      return true;
    } catch (e) {
      print('Error rejecting delivery: $e');
      return false;
    }
  }

  // Submit review for doer (by poster)
  Future<bool> submitReview(String taskId, double rating, String reviewMessage) async {
    try {
      // First, get the task to find the doer ID
      final task = await getTask(taskId);
      if (task == null || task.doerId == null) {
        print('Error: Task not found or no doer assigned');
        return false;
      }

      // Update the task with the review
      await _tasksCollection.doc(taskId).update({
        'ratingByPoster': rating,
        'reviewMessageByPoster': reviewMessage,
      });

      // Update the doer's user document
      await _updateDoerRating(task.doerId!, rating);

      return true;
    } catch (e) {
      print('Error submitting review: $e');
      return false;
    }
  }

  // Submit review for poster (by doer)
  Future<bool> submitDoerReview(String taskId, double rating, String reviewMessage) async {
    try {
      // First, get the task to find the poster ID
      final task = await getTask(taskId);
      if (task == null) {
        print('Error: Task not found');
        return false;
      }

      // Update the task with the review
      await _tasksCollection.doc(taskId).update({
        'ratingByDoer': rating,
        'reviewMessageByDoer': reviewMessage,
      });

      // Update the poster's user document
      await _updatePosterRating(task.posterId, rating);

      return true;
    } catch (e) {
      print('Error submitting doer review: $e');
      return false;
    }
  }

  // Update doer's rating in users collection
  Future<void> _updateDoerRating(String doerId, double newRating) async {
    try {
      // Get the current user document
      final userDoc = await _firestore.collection('users').doc(doerId).get();
      if (!userDoc.exists) {
        print('Error: Doer user document not found');
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final currentRatings = Map<String, double>.from(userData['ratings'] ?? {});
      final currentAsDoerRating = currentRatings['asDoer'] ?? 0.0;
      final currentNumberOfReviews = userData['numberofReviewsAsDoer'] ?? 0;

      // Calculate new average rating
      final newNumberOfReviews = currentNumberOfReviews + 1;
      final newAsDoerRating = ((currentAsDoerRating * currentNumberOfReviews) + newRating) / newNumberOfReviews;

      // Update the user document
      await _firestore.collection('users').doc(doerId).update({
        'ratings.asDoer': newAsDoerRating,
        'numberofReviewsAsDoer': newNumberOfReviews,
      });

      print('Successfully updated doer rating: $newAsDoerRating, reviews: $newNumberOfReviews');
    } catch (e) {
      print('Error updating doer rating: $e');
      rethrow;
    }
  }

  // Update poster's rating in users collection
  Future<void> _updatePosterRating(String posterId, double newRating) async {
    try {
      // Get the current user document
      final userDoc = await _firestore.collection('users').doc(posterId).get();
      if (!userDoc.exists) {
        print('Error: Poster user document not found');
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final currentRatings = Map<String, double>.from(userData['ratings'] ?? {});
      final currentAsPosterRating = currentRatings['asPoster'] ?? 0.0;
      final currentNumberOfReviews = userData['numberofReviewsAsPoster'] ?? 0;

      // Calculate new average rating
      final newNumberOfReviews = currentNumberOfReviews + 1;
      final newAsPosterRating = ((currentAsPosterRating * currentNumberOfReviews) + newRating) / newNumberOfReviews;

      // Update the user document
      await _firestore.collection('users').doc(posterId).update({
        'ratings.asPoster': newAsPosterRating,
        'numberofReviewsAsPoster': newNumberOfReviews,
      });

      print('Successfully updated poster rating: $newAsPosterRating, reviews: $newNumberOfReviews');
    } catch (e) {
      print('Error updating poster rating: $e');
      rethrow;
    }
  }

  // Delete task
  Future<bool> deleteTask(String taskId) async {
    try {
      await _tasksCollection.doc(taskId).delete();
      return true;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }

  // Get task applications
  Future<List<TaskApplicationModel>> getTaskApplications(String taskId) async {
    try {
      final querySnapshot = await _applicationsCollection
          .where('taskId', isEqualTo: taskId)
          .orderBy('appliedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TaskApplicationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting task applications: $e');
      return [];
    }
  }

  // Create task review
  Future<bool> createTaskReview(TaskReviewModel review) async {
    try {
      await _reviewsCollection.add(review.toMap());
      return true;
    } catch (e) {
      print('Error creating task review: $e');
      return false;
    }
  }

  // Get task reviews
  Future<List<TaskReviewModel>> getTaskReviews(String taskId) async {
    try {
      final querySnapshot = await _reviewsCollection
          .where('taskId', isEqualTo: taskId)
          .orderBy('reviewedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TaskReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting task reviews: $e');
      return [];
    }
  }

  // Get user reviews
  Future<List<TaskReviewModel>> getUserReviews(String userId) async {
    try {
      final querySnapshot = await _reviewsCollection
          .where('reviewedUserId', isEqualTo: userId)
          .orderBy('reviewedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TaskReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user reviews: $e');
      return [];
    }
  }

  // Real-time listeners
  Stream<List<TaskModel>> getTasksStream({
    String? category,
    TaskStatus? status,
  }) {
    Query query = _tasksCollection;

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<TaskModel>> getUserTasksStream(String userId, {TaskStatus? status}) {
    Query query = _tasksCollection.where('posterId', isEqualTo: userId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList());
  }

  Stream<TaskModel?> getTaskStream(String taskId) {
    return _tasksCollection
        .doc(taskId)
        .snapshots()
        .map((doc) => doc.exists ? TaskModel.fromFirestore(doc) : null);
  }

  Stream<List<TaskApplicationModel>> getTaskApplicationsStream(String taskId) {
    return _applicationsCollection
        .where('taskId', isEqualTo: taskId)
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskApplicationModel.fromFirestore(doc))
            .toList());
  }

  // Debug method to check all tasks
  Future<void> debugCheckAllTasks(String userId) async {
    try {
      print('Debug: Checking all tasks for userId: $userId');
      final querySnapshot = await _tasksCollection.get();
      print('Debug: Total tasks in database: ${querySnapshot.docs.length}');
      
      int tasksWithDoerId = 0;
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final doerId = data['doerId'];
        if (doerId == userId) {
          tasksWithDoerId++;
          print('Debug: Found task with doerId $userId: ${data['title']}, status: ${data['status']}');
        }
      }
      print('Debug: Total tasks with doerId $userId: $tasksWithDoerId');
    } catch (e) {
      print('Error in debug method: $e');
    }
  }

  // Debug method to test basic access to tasks collection
  Future<void> debugTestTasksAccess() async {
    try {
      print('Debug: Testing basic access to tasks collection...');
      final querySnapshot = await _tasksCollection.limit(1).get();
      print('Debug: Successfully accessed tasks collection. Found ${querySnapshot.docs.length} documents');
    } catch (e) {
      print('Debug: Error accessing tasks collection: $e');
    }
  }

  // NEW: Mutual Tasking Methods - Proposal Based System

  // Get mutual tasks with filtering
  Future<List<TaskModel>> getMutualTasks({TaskStatus? status, MutualStatus? mutualStatus}) async {
    try {
      Query query = _tasksCollection.where('isMutual', isEqualTo: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final querySnapshot = await query.get();
      
      List<TaskModel> tasks = querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();

      // Apply mutual status filter in memory
      if (mutualStatus != null) {
        tasks = tasks.where((task) => task.mutualStatus == mutualStatus).toList();
      }

      // Sort by createdAt in memory
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return tasks;
    } catch (e) {
      print('Error getting mutual tasks: $e');
      return [];
    }
  }

  // Get user's mutual tasks
  Future<List<TaskModel>> getUserMutualTasks(String userId, {TaskStatus? status, MutualStatus? mutualStatus}) async {
    try {
      Query query = _tasksCollection
          .where('posterId', isEqualTo: userId)
          .where('isMutual', isEqualTo: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      final querySnapshot = await query.get();
      
      List<TaskModel> tasks = querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();

      // Apply mutual status filter in memory
      if (mutualStatus != null) {
        tasks = tasks.where((task) => task.mutualStatus == mutualStatus).toList();
      }

      // Sort by createdAt in memory
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return tasks;
    } catch (e) {
      print('Error getting user mutual tasks: $e');
      return [];
    }
  }

  // Get mutual proposals for user's tasks
  Future<List<TaskModel>> getMutualProposals(String userId) async {
    try {
      Query query = _tasksCollection
          .where('posterId', isEqualTo: userId)
          .where('isMutual', isEqualTo: true);

      final querySnapshot = await query.get();
      
      List<TaskModel> tasks = querySnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();

      // Filter tasks that have pending proposals
      tasks = tasks.where((task) => task.hasPendingMutualProposals()).toList();

      // Sort by createdAt in memory
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return tasks;
    } catch (e) {
      print('Error getting mutual proposals: $e');
      return [];
    }
  }

  // Propose mutual task exchange (NEW: Add to proposals list)
  Future<bool> proposeMutualTask(String targetTaskId, String offeredTaskId, String proposerId) async {
    try {
      // Validate that the offered task belongs to the proposer
      final offeredTask = await getTask(offeredTaskId);
      if (offeredTask == null || offeredTask.posterId != proposerId) {
        print('Error: Offered task not found or does not belong to proposer');
        return false;
      }

      // Validate that the target task is mutual and open
      final targetTask = await getTask(targetTaskId);
      if (targetTask == null || !targetTask.isMutual || !targetTask.isOpen) {
        print('Error: Target task not found or not available for mutual exchange');
        return false;
      }

      // Check if proposer is not the poster of the target task
      if (targetTask.posterId == proposerId) {
        print('Error: Cannot propose to own task');
        return false;
      }

      // Check if user has a pending proposal to this task
      if (targetTask.mutualProposals.any((p) => p.proposerUserId == proposerId && p.status == MutualStatus.pending)) {
        print('Error: User already has a pending proposal to this task');
        return false;
      }

      // Check if user has already proposed with this specific task and it was rejected
      if (targetTask.mutualProposals.any((p) => 
          p.proposerUserId == proposerId && 
          p.offeredTaskId == offeredTaskId && 
          p.status == MutualStatus.rejected)) {
        print('Error: User has already proposed with this specific task and it was rejected');
        return false;
      }

      // Create new proposal
      final newProposal = MutualProposal(
        proposerUserId: proposerId,
        offeredTaskId: offeredTaskId,
        proposedAt: DateTime.now(),
        status: MutualStatus.pending,
      );

      // Add proposal to the target task's mutualProposals list
      final currentProposals = List<MutualProposal>.from(targetTask.mutualProposals);
      currentProposals.add(newProposal);

      // Update the target task with the new proposal
      await _tasksCollection.doc(targetTaskId).update({
        'mutualProposals': currentProposals.map((p) => p.toMap()).toList(),
      });

      return true;
    } catch (e) {
      print('Error proposing mutual task: $e');
      return false;
    }
  }

  // Accept mutual task proposal (NEW: Move proposal data to main fields)
  Future<bool> acceptMutualProposal(String taskId, String proposerUserId) async {
    try {
      // Get the task
      final task = await getTask(taskId);
      if (task == null) {
        print('Error: Task not found');
        return false;
      }

      // Find the proposal
      final proposal = task.mutualProposals.firstWhere(
        (p) => p.proposerUserId == proposerUserId && p.status == MutualStatus.pending,
        orElse: () => throw Exception('Proposal not found'),
      );

      // Get the offered task
      final offeredTask = await getTask(proposal.offeredTaskId);
      if (offeredTask == null) {
        print('Error: Offered task not found');
        return false;
      }

      // Update the target task: move proposal data to main fields and accept
      await _tasksCollection.doc(taskId).update({
        'mutualOfferTaskId': proposal.offeredTaskId,
        'mutualPartnerUserId': proposal.proposerUserId,
        'mutualStatus': MutualStatus.accepted.name,
        'status': TaskStatus.assigned.name,
        'doerId': offeredTask.posterId,
        'acceptedAt': Timestamp.fromDate(DateTime.now()),
        // Update the proposal status to accepted
        'mutualProposals': task.mutualProposals.map((p) {
          if (p.proposerUserId == proposerUserId) {
            return p.copyWith(status: MutualStatus.accepted).toMap();
          }
          return p.toMap();
        }).toList(),
      });

      // Update the offered task: assign the target task's poster as doer
      await _tasksCollection.doc(proposal.offeredTaskId).update({
        'mutualOfferTaskId': taskId,
        'mutualPartnerUserId': task.posterId,
        'mutualStatus': MutualStatus.accepted.name,
        'status': TaskStatus.assigned.name,
        'doerId': task.posterId,
        'acceptedAt': Timestamp.fromDate(DateTime.now()),
      });

      return true;
    } catch (e) {
      print('Error accepting mutual proposal: $e');
      return false;
    }
  }

  // Reject mutual task proposal (NEW: Update proposal status)
  Future<bool> rejectMutualProposal(String taskId, String proposerUserId) async {
    try {
      // Get the task
      final task = await getTask(taskId);
      if (task == null) {
        print('Error: Task not found');
        return false;
      }

      // Update the proposal status to rejected
      await _tasksCollection.doc(taskId).update({
        'mutualProposals': task.mutualProposals.map((p) {
          if (p.proposerUserId == proposerUserId) {
            return p.copyWith(status: MutualStatus.rejected).toMap();
          }
          return p.toMap();
        }).toList(),
      });

      return true;
    } catch (e) {
      print('Error rejecting mutual proposal: $e');
      return false;
    }
  }

  // Complete mutual exchange when both tasks are done
  Future<bool> completeMutualExchange(String taskId, String partnerTaskId) async {
    try {
      // Get both tasks
      final task = await getTask(taskId);
      final partnerTask = await getTask(partnerTaskId);
      
      if (task == null || partnerTask == null) {
        print('Error: One or both tasks not found');
        return false;
      }

      // Check if both tasks are completed
      if (task.status != TaskStatus.completed || partnerTask.status != TaskStatus.completed) {
        print('Error: Both tasks must be completed to finalize mutual exchange');
        return false;
      }

      // Update both tasks to completed mutual status
      await _tasksCollection.doc(taskId).update({
        'mutualStatus': MutualStatus.completed.name,
      });

      await _tasksCollection.doc(partnerTaskId).update({
        'mutualStatus': MutualStatus.completed.name,
      });

      return true;
    } catch (e) {
      print('Error completing mutual exchange: $e');
      return false;
    }
  }
} 