import 'package:flutter/material.dart';
import '../../../model/task_models/task_model.dart';
import '../../../model/task_models/task_application_model.dart';
import '../../../model/task_models/task_review_model.dart';
import '../../../services/task_service.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  
  // State variables
  List<TaskModel> _tasks = [];
  List<TaskModel> _userTasks = [];
  List<TaskModel> _acceptedTasks = [];
  List<TaskApplicationModel> _taskApplications = [];
  List<TaskReviewModel> _taskReviews = [];
  
  // NEW: Mutual tasking state variables
  List<TaskModel> _mutualTasks = [];
  List<TaskModel> _mutualProposals = [];
  bool _showMutualTasks = false;
  MutualStatus? _selectedMutualStatus;
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedCategory;
  String? _searchQuery;
  TaskStatus? _selectedStatus;

  // Getters
  List<TaskModel> get tasks => _tasks;
  List<TaskModel> get userTasks => _userTasks;
  List<TaskModel> get acceptedTasks => _acceptedTasks;
  List<TaskApplicationModel> get taskApplications => _taskApplications;
  List<TaskReviewModel> get taskReviews => _taskReviews;
  
  // NEW: Mutual tasking getters
  List<TaskModel> get mutualTasks => _mutualTasks;
  List<TaskModel> get mutualProposals => _mutualProposals;
  bool get showMutualTasks => _showMutualTasks;
  MutualStatus? get selectedMutualStatus => _selectedMutualStatus;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;
  String? get searchQuery => _searchQuery;
  TaskStatus? get selectedStatus => _selectedStatus;

  // Get filtered tasks
  List<TaskModel> get filteredTasks {
    List<TaskModel> filtered = _tasks.where((task) => task.isOpen).toList();

    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered.where((task) => task.category == _selectedCategory).toList();
    }

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filtered = filtered.where((task) =>
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query) ||
          task.location.toLowerCase().contains(query)).toList();
    }

    // NEW: Apply mutual task filter
    if (_showMutualTasks) {
      filtered = filtered.where((task) => task.isMutual).toList();
    }

    return filtered;
  }

  // NEW: Get filtered mutual tasks
  List<TaskModel> get filteredMutualTasks {
    List<TaskModel> filtered = _mutualTasks.where((task) => task.isOpen).toList();

    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered.where((task) => task.category == _selectedCategory).toList();
    }

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filtered = filtered.where((task) =>
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query) ||
          task.location.toLowerCase().contains(query)).toList();
    }

    if (_selectedMutualStatus != null) {
      filtered = filtered.where((task) => task.mutualStatus == _selectedMutualStatus).toList();
    }

    return filtered;
  }

  // Get user tasks by status
  List<TaskModel> getUserTasksByStatus(TaskStatus? status) {
    if (status == null) return _userTasks;
    return _userTasks.where((task) => task.status == status).toList();
  }

  // Get accepted tasks by status
  List<TaskModel> getAcceptedTasksByStatus(TaskStatus? status) {
    if (status == null) return _acceptedTasks;
    return _acceptedTasks.where((task) => task.status == status).toList();
  }

  // NEW: Get user mutual tasks by status
  List<TaskModel> getUserMutualTasksByStatus(TaskStatus? status) {
    if (status == null) return _mutualTasks;
    return _mutualTasks.where((task) => task.status == status).toList();
  }

  // Load tasks
  Future<void> loadTasks({String? category, String? searchQuery, bool? isMutual}) async {
    try {
      _setLoading(true);
      _clearError();

      _selectedCategory = category;
      _searchQuery = searchQuery;

      final tasks = await _taskService.getTasks(
        category: category,
        searchQuery: searchQuery,
        isMutual: isMutual,
      );

      _tasks = tasks;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load tasks: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load user tasks
  Future<void> loadUserTasks(String userId, {TaskStatus? status, bool? isMutual}) async {
    try {
      _setLoading(true);
      _clearError();

      _selectedStatus = status;

      final tasks = await _taskService.getUserTasks(userId, status: status, isMutual: isMutual);
      _userTasks = tasks;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user tasks: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load accepted tasks
  Future<void> loadAcceptedTasks(String userId, {TaskStatus? status}) async {
    try {
      print('Debug: TaskProvider.loadAcceptedTasks called for userId: $userId');
      _setLoading(true);
      _clearError();

      // Debug: Test basic access first
      await _taskService.debugTestTasksAccess();
      
      // Debug: Check all tasks first
      await _taskService.debugCheckAllTasks(userId);

      final tasks = await _taskService.getAcceptedTasks(userId, status: status);
      print('Debug: TaskService returned ${tasks.length} accepted tasks');
      _acceptedTasks = tasks;
      print('Debug: Updated _acceptedTasks with ${_acceptedTasks.length} tasks');
      notifyListeners();
    } catch (e) {
      print('Debug: Error in loadAcceptedTasks: $e');
      _setError('Failed to load accepted tasks: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create task
  Future<bool> createTask(TaskModel task) async {
    try {
      _setLoading(true);
      _clearError();

      final createdTask = await _taskService.createTask(task);
      if (createdTask != null) {
        _tasks.insert(0, createdTask);
        _userTasks.insert(0, createdTask);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to create task: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update task status
  Future<bool> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _taskService.updateTaskStatus(taskId, status);
      if (success) {
        // Update local state
        _updateTaskInLists(taskId, status);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to update task status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Apply for task
  Future<bool> applyForTask(String taskId, String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _taskService.applyForTask(taskId, userId);
      if (success) {
        // Update the task locally to reflect the application
        _updateTaskWithApplication(taskId, userId);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to apply for task: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Hire an applicant
  Future<bool> hireApplicant(String taskId, String applicantId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _taskService.hireApplicant(taskId, applicantId);
      if (success) {
        // Update task status and doerId locally
        _updateTaskWithHiring(taskId, applicantId);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to hire applicant: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Deliver task
  Future<bool> deliverTask(String taskId, String message, String? imageUrl) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _taskService.deliverTask(taskId, message, imageUrl);
      if (success) {
        // Update task status and delivery proof locally
        _updateTaskWithDelivery(taskId, message, imageUrl);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to deliver task: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Accept delivery
  Future<bool> acceptDelivery(String taskId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _taskService.acceptDelivery(taskId);
      if (success) {
        // Update task status locally to completed
        _updateTaskInLists(taskId, TaskStatus.completed);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to accept delivery: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reject delivery
  Future<bool> rejectDelivery(String taskId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _taskService.rejectDelivery(taskId);
      if (success) {
        // Update task status locally
        _updateTaskInLists(taskId, TaskStatus.assigned);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to reject delivery: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Submit review for doer (by poster)
  Future<bool> submitReview(String taskId, double rating, String reviewMessage) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _taskService.submitReview(taskId, rating, reviewMessage);
      if (success) {
        // Update task with review locally
        _updateTaskWithReview(taskId, rating, reviewMessage);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to submit review: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Submit review for poster (by doer)
  Future<bool> submitDoerReview(String taskId, double rating, String reviewMessage) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _taskService.submitDoerReview(taskId, rating, reviewMessage);
      if (success) {
        // Update task with doer review locally
        _updateTaskWithDoerReview(taskId, rating, reviewMessage);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to submit doer review: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get task applicants
  Future<List<Map<String, dynamic>>> getTaskApplicants(String taskId) async {
    try {
      _setLoading(true);
      _clearError();

      final applicants = await _taskService.getTaskApplicants(taskId);
      return applicants;
    } catch (e) {
      _setError('Failed to get task applicants: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Delete task
  Future<bool> deleteTask(String taskId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _taskService.deleteTask(taskId);
      if (success) {
        // Remove from all local lists
        _tasks.removeWhere((task) => task.id == taskId);
        _userTasks.removeWhere((task) => task.id == taskId);
        _acceptedTasks.removeWhere((task) => task.id == taskId);
        _mutualTasks.removeWhere((task) => task.id == taskId);
        
        // Notify listeners immediately to update UI
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to delete task: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load task applications
  Future<void> loadTaskApplications(String taskId) async {
    try {
      _setLoading(true);
      _clearError();

      final applications = await _taskService.getTaskApplications(taskId);
      _taskApplications = applications;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load task applications: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create task review
  Future<bool> createTaskReview(TaskReviewModel review) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _taskService.createTaskReview(review);
      if (success) {
        _taskReviews.insert(0, review);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to create task review: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load task reviews
  Future<void> loadTaskReviews(String taskId) async {
    try {
      _setLoading(true);
      _clearError();

      final reviews = await _taskService.getTaskReviews(taskId);
      _taskReviews = reviews;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load task reviews: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load user reviews
  Future<void> loadUserReviews(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final reviews = await _taskService.getUserReviews(userId);
      _taskReviews = reviews;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user reviews: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Set filters
  void setCategoryFilter(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(TaskStatus? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  // NEW: Set mutual task filters
  void setMutualTaskFilter(bool showMutual) {
    _showMutualTasks = showMutual;
    notifyListeners();
  }

  void setMutualStatusFilter(MutualStatus? status) {
    _selectedMutualStatus = status;
    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _selectedCategory = null;
    _searchQuery = null;
    _selectedStatus = null;
    _showMutualTasks = false;
    _selectedMutualStatus = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _clearError();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _updateTaskInLists(String taskId, TaskStatus status) {
    // Update in tasks list
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(status: status);
    }

    // Update in user tasks list
    final userTaskIndex = _userTasks.indexWhere((task) => task.id == taskId);
    if (userTaskIndex != -1) {
      _userTasks[userTaskIndex] = _userTasks[userTaskIndex].copyWith(status: status);
    }

    // Update in accepted tasks list
    final acceptedTaskIndex = _acceptedTasks.indexWhere((task) => task.id == taskId);
    if (acceptedTaskIndex != -1) {
      _acceptedTasks[acceptedTaskIndex] = _acceptedTasks[acceptedTaskIndex].copyWith(status: status);
    }

    // Update in mutual tasks list
    final mutualTaskIndex = _mutualTasks.indexWhere((task) => task.id == taskId);
    if (mutualTaskIndex != -1) {
      _mutualTasks[mutualTaskIndex] = _mutualTasks[mutualTaskIndex].copyWith(status: status);
    }

    // Notify listeners to update the UI immediately
    notifyListeners();
  }

  // Update task with application
  void _updateTaskWithApplication(String taskId, String userId) {
    // Add the user to the applicants list for the task
    final applicationData = {
      'userId': userId,
      'appliedAt': DateTime.now(),
    };

    // Update in tasks list
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final currentTask = _tasks[taskIndex];
      final updatedApplicants = List<Map<String, dynamic>>.from(currentTask.applicants);
      updatedApplicants.add(applicationData);
      _tasks[taskIndex] = currentTask.copyWith(applicants: updatedApplicants);
    }

    // Update in user tasks list
    final userTaskIndex = _userTasks.indexWhere((task) => task.id == taskId);
    if (userTaskIndex != -1) {
      final currentTask = _userTasks[userTaskIndex];
      final updatedApplicants = List<Map<String, dynamic>>.from(currentTask.applicants);
      updatedApplicants.add(applicationData);
      _userTasks[userTaskIndex] = currentTask.copyWith(applicants: updatedApplicants);
    }

    // Update in accepted tasks list
    final acceptedTaskIndex = _acceptedTasks.indexWhere((task) => task.id == taskId);
    if (acceptedTaskIndex != -1) {
      final currentTask = _acceptedTasks[acceptedTaskIndex];
      final updatedApplicants = List<Map<String, dynamic>>.from(currentTask.applicants);
      updatedApplicants.add(applicationData);
      _acceptedTasks[acceptedTaskIndex] = currentTask.copyWith(applicants: updatedApplicants);
    }

    // Update in mutual tasks list
    final mutualTaskIndex = _mutualTasks.indexWhere((task) => task.id == taskId);
    if (mutualTaskIndex != -1) {
      final currentTask = _mutualTasks[mutualTaskIndex];
      final updatedApplicants = List<Map<String, dynamic>>.from(currentTask.applicants);
      updatedApplicants.add(applicationData);
      _mutualTasks[mutualTaskIndex] = currentTask.copyWith(applicants: updatedApplicants);
    }

    // Notify listeners to update the UI immediately
    notifyListeners();
  }

  // Update task with hiring information
  void _updateTaskWithHiring(String taskId, String doerId) {
    final now = DateTime.now();
    
    // Update in tasks list
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(
        status: TaskStatus.assigned,
        doerId: doerId,
        acceptedAt: now,
      );
    }

    // Update in user tasks list
    final userTaskIndex = _userTasks.indexWhere((task) => task.id == taskId);
    if (userTaskIndex != -1) {
      _userTasks[userTaskIndex] = _userTasks[userTaskIndex].copyWith(
        status: TaskStatus.assigned,
        doerId: doerId,
        acceptedAt: now,
      );
    }

    // Update in accepted tasks list
    final acceptedTaskIndex = _acceptedTasks.indexWhere((task) => task.id == taskId);
    if (acceptedTaskIndex != -1) {
      _acceptedTasks[acceptedTaskIndex] = _acceptedTasks[acceptedTaskIndex].copyWith(
        status: TaskStatus.assigned,
        doerId: doerId,
        acceptedAt: now,
      );
    }

    // Update in mutual tasks list
    final mutualTaskIndex = _mutualTasks.indexWhere((task) => task.id == taskId);
    if (mutualTaskIndex != -1) {
      _mutualTasks[mutualTaskIndex] = _mutualTasks[mutualTaskIndex].copyWith(
        status: TaskStatus.assigned,
        doerId: doerId,
        acceptedAt: now,
      );
    }

    // Notify listeners to update the UI
    notifyListeners();
  }

  // Update task with delivery information
  void _updateTaskWithDelivery(String taskId, String message, String? imageUrl) {
    final now = DateTime.now();
    final Map<String, dynamic> deliveryProofData = {
      'type': imageUrl != null ? 'image' : 'text',
      'url': imageUrl,
      'uploadedAt': now,
      'message': message,
    };
    
    // Update in tasks list
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(
        status: TaskStatus.delivered,
        deliveryProof: deliveryProofData,
      );
    }

    // Update in user tasks list
    final userTaskIndex = _userTasks.indexWhere((task) => task.id == taskId);
    if (userTaskIndex != -1) {
      _userTasks[userTaskIndex] = _userTasks[userTaskIndex].copyWith(
        status: TaskStatus.delivered,
        deliveryProof: deliveryProofData,
      );
    }

    // Update in accepted tasks list
    final acceptedTaskIndex = _acceptedTasks.indexWhere((task) => task.id == taskId);
    if (acceptedTaskIndex != -1) {
      _acceptedTasks[acceptedTaskIndex] = _acceptedTasks[acceptedTaskIndex].copyWith(
        status: TaskStatus.delivered,
        deliveryProof: deliveryProofData,
      );
    }

    // Update in mutual tasks list
    final mutualTaskIndex = _mutualTasks.indexWhere((task) => task.id == taskId);
    if (mutualTaskIndex != -1) {
      _mutualTasks[mutualTaskIndex] = _mutualTasks[mutualTaskIndex].copyWith(
        status: TaskStatus.delivered,
        deliveryProof: deliveryProofData,
      );
    }

    // Notify listeners to update the UI
    notifyListeners();
  }

  // Update task with review information
  void _updateTaskWithReview(String taskId, double rating, String reviewMessage) {
    // Update in tasks list
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(
        ratingByPoster: rating,
        reviewMessageByPoster: reviewMessage,
      );
    }

    // Update in user tasks list
    final userTaskIndex = _userTasks.indexWhere((task) => task.id == taskId);
    if (userTaskIndex != -1) {
      _userTasks[userTaskIndex] = _userTasks[userTaskIndex].copyWith(
        ratingByPoster: rating,
        reviewMessageByPoster: reviewMessage,
      );
    }

    // Update in accepted tasks list
    final acceptedTaskIndex = _acceptedTasks.indexWhere((task) => task.id == taskId);
    if (acceptedTaskIndex != -1) {
      _acceptedTasks[acceptedTaskIndex] = _acceptedTasks[acceptedTaskIndex].copyWith(
        ratingByPoster: rating,
        reviewMessageByPoster: reviewMessage,
      );
    }

    // Update in mutual tasks list
    final mutualTaskIndex = _mutualTasks.indexWhere((task) => task.id == taskId);
    if (mutualTaskIndex != -1) {
      _mutualTasks[mutualTaskIndex] = _mutualTasks[mutualTaskIndex].copyWith(
        ratingByPoster: rating,
        reviewMessageByPoster: reviewMessage,
      );
    }

    // Notify listeners to update the UI immediately
    notifyListeners();
  }

  // Update task with doer review information
  void _updateTaskWithDoerReview(String taskId, double rating, String reviewMessage) {
    // Update in tasks list
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(
        ratingByDoer: rating,
        reviewMessageByDoer: reviewMessage,
      );
    }

    // Update in user tasks list
    final userTaskIndex = _userTasks.indexWhere((task) => task.id == taskId);
    if (userTaskIndex != -1) {
      _userTasks[userTaskIndex] = _userTasks[userTaskIndex].copyWith(
        ratingByDoer: rating,
        reviewMessageByDoer: reviewMessage,
      );
    }

    // Update in accepted tasks list
    final acceptedTaskIndex = _acceptedTasks.indexWhere((task) => task.id == taskId);
    if (acceptedTaskIndex != -1) {
      _acceptedTasks[acceptedTaskIndex] = _acceptedTasks[acceptedTaskIndex].copyWith(
        ratingByDoer: rating,
        reviewMessageByDoer: reviewMessage,
      );
    }

    // Update in mutual tasks list
    final mutualTaskIndex = _mutualTasks.indexWhere((task) => task.id == taskId);
    if (mutualTaskIndex != -1) {
      _mutualTasks[mutualTaskIndex] = _mutualTasks[mutualTaskIndex].copyWith(
        ratingByDoer: rating,
        reviewMessageByDoer: reviewMessage,
      );
    }

    // Notify listeners to update the UI immediately
    notifyListeners();
  }

  // NEW: Load mutual tasks
  Future<void> loadMutualTasks({TaskStatus? status, MutualStatus? mutualStatus}) async {
    try {
      _setLoading(true);
      _clearError();

      final tasks = await _taskService.getMutualTasks(status: status, mutualStatus: mutualStatus);
      _mutualTasks = tasks;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load mutual tasks: $e');
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Load user mutual tasks
  Future<void> loadUserMutualTasks(String userId, {TaskStatus? status, MutualStatus? mutualStatus}) async {
    try {
      _setLoading(true);
      _clearError();

      final tasks = await _taskService.getUserMutualTasks(userId, status: status, mutualStatus: mutualStatus);
      _mutualTasks = tasks;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load user mutual tasks: $e');
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Load mutual proposals
  Future<void> loadMutualProposals(String userId) async {
    try {
      _setLoading(true);
      _clearError();

      final proposals = await _taskService.getMutualProposals(userId);
      _mutualProposals = proposals;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load mutual proposals: $e');
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Propose mutual task
  Future<bool> proposeMutualTask(String targetTaskId, String offeredTaskId, String proposerId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _taskService.proposeMutualTask(targetTaskId, offeredTaskId, proposerId);
      if (success) {
        // Update the target task locally to reflect the proposal
        _updateTaskWithMutualProposal(targetTaskId, offeredTaskId, proposerId);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to propose mutual task: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Accept mutual proposal
  Future<bool> acceptMutualProposal(String taskId, String proposerUserId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _taskService.acceptMutualProposal(taskId, proposerUserId);
      if (success) {
        // Update both tasks locally
        _updateTaskWithMutualAcceptance(taskId, proposerUserId);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to accept mutual proposal: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Reject mutual proposal
  Future<bool> rejectMutualProposal(String taskId, String proposerUserId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _taskService.rejectMutualProposal(taskId, proposerUserId);
      if (success) {
        // Update the task locally
        _updateTaskWithMutualRejection(taskId, proposerUserId);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to reject mutual proposal: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Complete mutual exchange
  Future<bool> completeMutualExchange(String taskId, String partnerTaskId) async {
    try {
      _setLoading(true);
      _clearError();

      final success = await _taskService.completeMutualExchange(taskId, partnerTaskId);
      if (success) {
        // Update both tasks locally
        _updateTaskWithMutualCompletion(taskId, partnerTaskId);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to complete mutual exchange: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Update task with mutual proposal
  void _updateTaskWithMutualProposal(String taskId, String offeredTaskId, String proposerId) {
    final newProposal = MutualProposal(
      proposerUserId: proposerId,
      offeredTaskId: offeredTaskId,
      proposedAt: DateTime.now(),
      status: MutualStatus.pending,
    );

    // Update in tasks list
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final currentTask = _tasks[taskIndex];
      final updatedProposals = List<MutualProposal>.from(currentTask.mutualProposals);
      updatedProposals.add(newProposal);
      _tasks[taskIndex] = currentTask.copyWith(mutualProposals: updatedProposals);
    }

    // Update in user tasks list
    final userTaskIndex = _userTasks.indexWhere((task) => task.id == taskId);
    if (userTaskIndex != -1) {
      final currentTask = _userTasks[userTaskIndex];
      final updatedProposals = List<MutualProposal>.from(currentTask.mutualProposals);
      updatedProposals.add(newProposal);
      _userTasks[userTaskIndex] = currentTask.copyWith(mutualProposals: updatedProposals);
    }

    // Update in accepted tasks list
    final acceptedTaskIndex = _acceptedTasks.indexWhere((task) => task.id == taskId);
    if (acceptedTaskIndex != -1) {
      final currentTask = _acceptedTasks[acceptedTaskIndex];
      final updatedProposals = List<MutualProposal>.from(currentTask.mutualProposals);
      updatedProposals.add(newProposal);
      _acceptedTasks[acceptedTaskIndex] = currentTask.copyWith(mutualProposals: updatedProposals);
    }

    // Update in mutual tasks list
    final mutualTaskIndex = _mutualTasks.indexWhere((task) => task.id == taskId);
    if (mutualTaskIndex != -1) {
      final currentTask = _mutualTasks[mutualTaskIndex];
      final updatedProposals = List<MutualProposal>.from(currentTask.mutualProposals);
      updatedProposals.add(newProposal);
      _mutualTasks[mutualTaskIndex] = currentTask.copyWith(mutualProposals: updatedProposals);
    }

    notifyListeners();
  }

  // NEW: Update task with mutual acceptance
  void _updateTaskWithMutualAcceptance(String taskId, String proposerUserId) {
    final now = DateTime.now();
    
    // Update in tasks list
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final currentTask = _tasks[taskIndex];
      final proposal = currentTask.mutualProposals.firstWhere(
        (p) => p.proposerUserId == proposerUserId,
        orElse: () => throw Exception('Proposal not found'),
      );
      
      // Update proposal status and move to main fields
      final updatedProposals = currentTask.mutualProposals.map((p) {
        if (p.proposerUserId == proposerUserId) {
          return p.copyWith(status: MutualStatus.accepted);
        }
        return p;
      }).toList();
      
      _tasks[taskIndex] = currentTask.copyWith(
        status: TaskStatus.assigned,
        mutualStatus: MutualStatus.accepted,
        mutualOfferTaskId: proposal.offeredTaskId,
        mutualPartnerUserId: proposal.proposerUserId,
        acceptedAt: now,
        mutualProposals: updatedProposals,
      );
    }

    // Update in user tasks list
    final userTaskIndex = _userTasks.indexWhere((task) => task.id == taskId);
    if (userTaskIndex != -1) {
      final currentTask = _userTasks[userTaskIndex];
      final proposal = currentTask.mutualProposals.firstWhere(
        (p) => p.proposerUserId == proposerUserId,
        orElse: () => throw Exception('Proposal not found'),
      );
      
      final updatedProposals = currentTask.mutualProposals.map((p) {
        if (p.proposerUserId == proposerUserId) {
          return p.copyWith(status: MutualStatus.accepted);
        }
        return p;
      }).toList();
      
      _userTasks[userTaskIndex] = currentTask.copyWith(
        status: TaskStatus.assigned,
        mutualStatus: MutualStatus.accepted,
        mutualOfferTaskId: proposal.offeredTaskId,
        mutualPartnerUserId: proposal.proposerUserId,
        acceptedAt: now,
        mutualProposals: updatedProposals,
      );
    }

    // Update in accepted tasks list
    final acceptedTaskIndex = _acceptedTasks.indexWhere((task) => task.id == taskId);
    if (acceptedTaskIndex != -1) {
      final currentTask = _acceptedTasks[acceptedTaskIndex];
      final proposal = currentTask.mutualProposals.firstWhere(
        (p) => p.proposerUserId == proposerUserId,
        orElse: () => throw Exception('Proposal not found'),
      );
      
      final updatedProposals = currentTask.mutualProposals.map((p) {
        if (p.proposerUserId == proposerUserId) {
          return p.copyWith(status: MutualStatus.accepted);
        }
        return p;
      }).toList();
      
      _acceptedTasks[acceptedTaskIndex] = currentTask.copyWith(
        status: TaskStatus.assigned,
        mutualStatus: MutualStatus.accepted,
        mutualOfferTaskId: proposal.offeredTaskId,
        mutualPartnerUserId: proposal.proposerUserId,
        acceptedAt: now,
        mutualProposals: updatedProposals,
      );
    }

    // Update in mutual tasks list
    final mutualTaskIndex = _mutualTasks.indexWhere((task) => task.id == taskId);
    if (mutualTaskIndex != -1) {
      final currentTask = _mutualTasks[mutualTaskIndex];
      final proposal = currentTask.mutualProposals.firstWhere(
        (p) => p.proposerUserId == proposerUserId,
        orElse: () => throw Exception('Proposal not found'),
      );
      
      final updatedProposals = currentTask.mutualProposals.map((p) {
        if (p.proposerUserId == proposerUserId) {
          return p.copyWith(status: MutualStatus.accepted);
        }
        return p;
      }).toList();
      
      _mutualTasks[mutualTaskIndex] = currentTask.copyWith(
        status: TaskStatus.assigned,
        mutualStatus: MutualStatus.accepted,
        mutualOfferTaskId: proposal.offeredTaskId,
        mutualPartnerUserId: proposal.proposerUserId,
        acceptedAt: now,
        mutualProposals: updatedProposals,
      );
    }

    notifyListeners();
  }

  // NEW: Update task with mutual rejection
  void _updateTaskWithMutualRejection(String taskId, String proposerUserId) {
    // Update in tasks list
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      final currentTask = _tasks[taskIndex];
      final updatedProposals = currentTask.mutualProposals.map((p) {
        if (p.proposerUserId == proposerUserId) {
          return p.copyWith(status: MutualStatus.rejected);
        }
        return p;
      }).toList();
      
      _tasks[taskIndex] = currentTask.copyWith(mutualProposals: updatedProposals);
    }

    // Update in user tasks list
    final userTaskIndex = _userTasks.indexWhere((task) => task.id == taskId);
    if (userTaskIndex != -1) {
      final currentTask = _userTasks[userTaskIndex];
      final updatedProposals = currentTask.mutualProposals.map((p) {
        if (p.proposerUserId == proposerUserId) {
          return p.copyWith(status: MutualStatus.rejected);
        }
        return p;
      }).toList();
      
      _userTasks[userTaskIndex] = currentTask.copyWith(mutualProposals: updatedProposals);
    }

    // Update in accepted tasks list
    final acceptedTaskIndex = _acceptedTasks.indexWhere((task) => task.id == taskId);
    if (acceptedTaskIndex != -1) {
      final currentTask = _acceptedTasks[acceptedTaskIndex];
      final updatedProposals = currentTask.mutualProposals.map((p) {
        if (p.proposerUserId == proposerUserId) {
          return p.copyWith(status: MutualStatus.rejected);
        }
        return p;
      }).toList();
      
      _acceptedTasks[acceptedTaskIndex] = currentTask.copyWith(mutualProposals: updatedProposals);
    }

    // Update in mutual tasks list
    final mutualTaskIndex = _mutualTasks.indexWhere((task) => task.id == taskId);
    if (mutualTaskIndex != -1) {
      final currentTask = _mutualTasks[mutualTaskIndex];
      final updatedProposals = currentTask.mutualProposals.map((p) {
        if (p.proposerUserId == proposerUserId) {
          return p.copyWith(status: MutualStatus.rejected);
        }
        return p;
      }).toList();
      
      _mutualTasks[mutualTaskIndex] = currentTask.copyWith(mutualProposals: updatedProposals);
    }

    notifyListeners();
  }

  // NEW: Update task with mutual completion
  void _updateTaskWithMutualCompletion(String taskId, String partnerTaskId) {
    // Update in tasks list
    final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(
        mutualStatus: MutualStatus.completed,
      );
    }

    // Update in user tasks list
    final userTaskIndex = _userTasks.indexWhere((task) => task.id == taskId);
    if (userTaskIndex != -1) {
      _userTasks[userTaskIndex] = _userTasks[userTaskIndex].copyWith(
        mutualStatus: MutualStatus.completed,
      );
    }

    // Update in accepted tasks list
    final acceptedTaskIndex = _acceptedTasks.indexWhere((task) => task.id == taskId);
    if (acceptedTaskIndex != -1) {
      _acceptedTasks[acceptedTaskIndex] = _acceptedTasks[acceptedTaskIndex].copyWith(
        mutualStatus: MutualStatus.completed,
      );
    }

    // Update in mutual tasks list
    final mutualTaskIndex = _mutualTasks.indexWhere((task) => task.id == taskId);
    if (mutualTaskIndex != -1) {
      _mutualTasks[mutualTaskIndex] = _mutualTasks[mutualTaskIndex].copyWith(
        mutualStatus: MutualStatus.completed,
      );
    }

    notifyListeners();
  }
} 