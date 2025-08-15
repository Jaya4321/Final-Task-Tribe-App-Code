class TaskValidators {
  // Title validation
  static String? validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return 'Task title is required';
    }
    
    if (title.trim().length < 5) {
      return 'Task title must be at least 5 characters long';
    }
    
    if (title.trim().length > 100) {
      return 'Task title must be less than 100 characters';
    }
    
    return null;
  }

  // Description validation
  static String? validateDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return 'Task description is required';
    }
    
    if (description.trim().length < 10) {
      return 'Task description must be at least 10 characters long';
    }
    
    if (description.trim().length > 1000) {
      return 'Task description must be less than 1000 characters';
    }
    
    return null;
  }

  // Category validation
  static String? validateCategory(String? category) {
    if (category == null || category.trim().isEmpty) {
      return 'Please select a category';
    }
    
    return null;
  }

  // Date validation
  static String? validateDate(String? date) {
    if (date == null || date.trim().isEmpty) {
      return 'Please select a date';
    }
    
    try {
      final selectedDate = DateTime.parse(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selectedDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      
      if (selectedDay.isBefore(today)) {
        return 'Date cannot be in the past';
      }
    } catch (e) {
      return 'Please enter a valid date';
    }
    
    return null;
  }

  // Time validation
  static String? validateTime(String? time) {
    if (time == null || time.trim().isEmpty) {
      return 'Please select a time';
    }
    
    return null;
  }

  // Location validation
  static String? validateLocation(String? location) {
    if (location == null || location.trim().isEmpty) {
      return 'Location is required';
    }
    
    if (location.trim().length < 3) {
      return 'Location must be at least 3 characters long';
    }
    
    if (location.trim().length > 200) {
      return 'Location must be less than 200 characters';
    }
    
    return null;
  }

  // Reward validation
  static String? validateReward(String? reward) {
    if (reward == null || reward.trim().isEmpty) {
      return 'Reward amount is required';
    }
    
    final rewardValue = double.tryParse(reward);
    if (rewardValue == null) {
      return 'Please enter a valid amount';
    }
    
    if (rewardValue < 0) {
      return 'Reward cannot be negative';
    }
    
    if (rewardValue > 10000) {
      return 'Reward cannot exceed £10,000';
    }
    
    return null;
  }

  // NEW: Reward validation for mutual tasks (allows 0)
  static String? validateRewardForMutual(String? reward, bool isMutual) {
    if (isMutual) {
      // For mutual tasks, reward can be 0 or empty
      if (reward == null || reward.trim().isEmpty) {
        return null; // No reward required for mutual tasks
      }
      
      final rewardValue = double.tryParse(reward);
      if (rewardValue == null) {
        return 'Please enter a valid amount';
      }
      
      if (rewardValue < 0) {
        return 'Reward cannot be negative';
      }
      
      if (rewardValue > 10000) {
        return 'Reward cannot exceed £10,000';
      }
      
      return null;
    } else {
      // For regular tasks, use standard validation
      return validateReward(reward);
    }
  }

  // Additional requirements validation
  static String? validateAdditionalRequirements(String? requirements) {
    if (requirements == null || requirements.trim().isEmpty) {
      return null; // Optional field
    }
    
    if (requirements.trim().length > 500) {
      return 'Additional requirements must be less than 500 characters';
    }
    
    return null;
  }

  // Application message validation
  static String? validateApplicationMessage(String? message) {
    if (message == null || message.trim().isEmpty) {
      return 'Please provide a message with your application';
    }
    
    if (message.trim().length < 10) {
      return 'Application message must be at least 10 characters long';
    }
    
    if (message.trim().length > 500) {
      return 'Application message must be less than 500 characters';
    }
    
    return null;
  }

  // Review text validation
  static String? validateReviewText(String? reviewText) {
    if (reviewText == null || reviewText.trim().isEmpty) {
      return 'Please provide a review';
    }
    
    if (reviewText.trim().length < 10) {
      return 'Review must be at least 10 characters long';
    }
    
    if (reviewText.trim().length > 500) {
      return 'Review must be less than 500 characters';
    }
    
    return null;
  }

  // Rating validation
  static String? validateRating(double? rating) {
    if (rating == null) {
      return 'Please provide a rating';
    }
    
    if (rating < 1.0 || rating > 5.0) {
      return 'Rating must be between 1 and 5';
    }
    
    return null;
  }

  // Task creation form validation
  static Map<String, String?> validateTaskForm({
    required String title,
    required String description,
    required String category,
    required String date,
    required String time,
    required String location,
    required String reward,
    String? additionalRequirements,
  }) {
    return {
      'title': validateTitle(title),
      'description': validateDescription(description),
      'category': validateCategory(category),
      'date': validateDate(date),
      'time': validateTime(time),
      'location': validateLocation(location),
      'reward': validateReward(reward),
      'additionalRequirements': validateAdditionalRequirements(additionalRequirements),
    };
  }

  // NEW: Mutual task creation form validation
  static Map<String, String?> validateMutualTaskForm({
    required String title,
    required String description,
    required String category,
    required String date,
    required String time,
    required String location,
    required String reward,
    String? additionalRequirements,
    required bool isMutual,
  }) {
    return {
      'title': validateTitle(title),
      'description': validateDescription(description),
      'category': validateCategory(category),
      'date': validateDate(date),
      'time': validateTime(time),
      'location': validateLocation(location),
      'reward': validateRewardForMutual(reward, isMutual),
      'additionalRequirements': validateAdditionalRequirements(additionalRequirements),
    };
  }

  // Application form validation
  static Map<String, String?> validateApplicationForm({
    required String message,
  }) {
    return {
      'message': validateApplicationMessage(message),
    };
  }

  // Review form validation
  static Map<String, String?> validateReviewForm({
    required double rating,
    required String reviewText,
  }) {
    return {
      'rating': validateRating(rating),
      'reviewText': validateReviewText(reviewText),
    };
  }

  // Check if form is valid
  static bool isFormValid(Map<String, String?> errors) {
    return errors.values.every((error) => error == null);
  }

  // Get error count
  static int getErrorCount(Map<String, String?> errors) {
    return errors.values.where((error) => error != null).length;
  }

  // Get first error
  static String? getFirstError(Map<String, String?> errors) {
    for (final error in errors.values) {
      if (error != null) {
        return error;
      }
    }
    return null;
  }
} 