import 'package:flutter/material.dart';
import '../../../model/task_models/task_model.dart';
import '../../../utils/task_validators.dart';
import '../../../constants/task_constants.dart';

class TaskFormProvider with ChangeNotifier {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _rewardController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();

  String _selectedCategory = '';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;
  Map<String, String?> _errors = {};
  
  // NEW: Mutual task state
  bool _isMutualTask = false;

  // Getters
  TextEditingController get titleController => _titleController;
  TextEditingController get descriptionController => _descriptionController;
  TextEditingController get locationController => _locationController;
  TextEditingController get rewardController => _rewardController;
  TextEditingController get requirementsController => _requirementsController;
  
  String get selectedCategory => _selectedCategory;
  DateTime? get selectedDate => _selectedDate;
  TimeOfDay? get selectedTime => _selectedTime;
  bool get isSubmitting => _isSubmitting;
  Map<String, String?> get errors => _errors;
  
  // NEW: Mutual task getter
  bool get isMutualTask => _isMutualTask;

  // Form validation
  bool get isFormValid {
    return _titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _selectedCategory.isNotEmpty &&
        _selectedDate != null &&
        _selectedTime != null &&
        _locationController.text.isNotEmpty &&
        (_isMutualTask || _rewardController.text.isNotEmpty) && // Allow empty reward for mutual tasks
        TaskValidators.isFormValid(_errors);
  }

  // Set category
  void setCategory(String category) {
    _selectedCategory = category;
    _validateForm();
    notifyListeners();
  }

  // Set date
  void setDate(DateTime date) {
    _selectedDate = date;
    _validateForm();
    notifyListeners();
  }

  // Set time
  void setTime(TimeOfDay time) {
    _selectedTime = time;
    _validateForm();
    notifyListeners();
  }

  // NEW: Set mutual task
  void setMutualTask(bool isMutual) {
    _isMutualTask = isMutual;
    _validateForm();
    notifyListeners();
  }

  // Set submitting state
  void setSubmitting(bool submitting) {
    _isSubmitting = submitting;
    notifyListeners();
  }

  // Validate form
  void validateForm() {
    _validateForm();
    notifyListeners();
  }

  // Validate specific field
  void validateField(String fieldName) {
    switch (fieldName) {
      case 'title':
        _errors['title'] = TaskValidators.validateTitle(_titleController.text);
        break;
      case 'description':
        _errors['description'] = TaskValidators.validateDescription(_descriptionController.text);
        break;
      case 'category':
        _errors['category'] = TaskValidators.validateCategory(_selectedCategory);
        break;
      case 'date':
        _errors['date'] = TaskValidators.validateDate(_selectedDate?.toIso8601String());
        break;
      case 'time':
        _errors['time'] = TaskValidators.validateTime(_formatTime(_selectedTime));
        break;
      case 'location':
        _errors['location'] = TaskValidators.validateLocation(_locationController.text);
        break;
      case 'reward':
        // NEW: Use mutual task validation for reward
        _errors['reward'] = TaskValidators.validateRewardForMutual(_rewardController.text, _isMutualTask);
        break;
      case 'requirements':
        _errors['requirements'] = TaskValidators.validateAdditionalRequirements(_requirementsController.text);
        break;
    }
    notifyListeners();
  }

  // Get task model from form
  TaskModel? getTaskModel(String posterId) {
    if (!isFormValid) return null;

    return TaskModel(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      date: _selectedDate!.toIso8601String().split('T')[0],
      time: _formatTime(_selectedTime)!,
      location: _locationController.text.trim(),
      reward: _isMutualTask ? 0.0 : double.parse(_rewardController.text), // 0 reward for mutual tasks
      additionalRequirements: _requirementsController.text.trim().isEmpty 
          ? null 
          : _requirementsController.text.trim(),
      status: TaskStatus.open,
      createdAt: DateTime.now(),
      posterId: posterId,
      isMutual: _isMutualTask, // NEW: Set mutual flag
    );
  }

  // Clear form
  void clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _rewardController.clear();
    _requirementsController.clear();
    // Reset to first category instead of clearing
    _selectedCategory = TaskCategories.categories.isNotEmpty 
        ? TaskCategories.categories.first 
        : '';
    _selectedDate = null;
    _selectedTime = null;
    _errors.clear();
    _isSubmitting = false;
    _isMutualTask = false; // NEW: Reset mutual task flag
    notifyListeners();
  }

  // Set error
  void setError(String field, String error) {
    _errors[field] = error;
    notifyListeners();
  }

  // Clear error
  void clearError(String field) {
    _errors.remove(field);
    notifyListeners();
  }

  // Clear all errors
  void clearAllErrors() {
    _errors.clear();
    notifyListeners();
  }

  // Get form data
  Map<String, dynamic> getFormData() {
    return {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'category': _selectedCategory,
      'date': _selectedDate?.toIso8601String().split('T')[0],
      'time': _formatTime(_selectedTime),
      'location': _locationController.text,
      'reward': _rewardController.text,
      'requirements': _requirementsController.text,
    };
  }

  // Reset to initial state
  void reset() {
    clearForm();
  }

  // Private validation method
  void _validateForm() {
    _errors = TaskValidators.validateMutualTaskForm(
      title: _titleController.text,
      description: _descriptionController.text,
      category: _selectedCategory,
      date: _selectedDate?.toIso8601String().split('T')[0] ?? '',
      time: _formatTime(_selectedTime) ?? '',
      location: _locationController.text,
      reward: _rewardController.text,
      additionalRequirements: _requirementsController.text,
      isMutual: _isMutualTask,
    );
  }

  // Helper method to format time
  String? _formatTime(TimeOfDay? time) {
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _rewardController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }
} 