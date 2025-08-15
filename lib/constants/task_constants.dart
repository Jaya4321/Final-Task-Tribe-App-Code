import 'package:flutter/material.dart';
import 'myColors.dart';
import '../model/task_models/task_model.dart';

// Task Categories
class TaskCategories {
  static const List<String> categories = [
    'Household',
    'Shopping',
    'Transportation',
    'Technology',
    'Education',
    'Entertainment',
    'Health & Fitness',
    'Other',
  ];

  static const Map<String, IconData> categoryIcons = {
    'Household': Icons.home,
    'Shopping': Icons.shopping_cart,
    'Transportation': Icons.directions_car,
    'Technology': Icons.computer,
    'Education': Icons.school,
    'Entertainment': Icons.movie,
    'Health & Fitness': Icons.fitness_center,
    'Other': Icons.more_horiz,
  };
}

// Task Status Colors
class TaskStatusColors {
  static Color getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.open:
        return successColor;
      case TaskStatus.assigned:
        return infoColor;
      case TaskStatus.delivered:
        return warningColor;
      case TaskStatus.completed:
        return successColor;
      case TaskStatus.cancelled:
        return errorColor;
    }
  }

  static String getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.open:
        return 'Open';
      case TaskStatus.assigned:
        return 'Assigned';
      case TaskStatus.delivered:
        return 'Delivered';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// Task UI Constants
class TaskUIConstants {
  // Spacing
  static const double cardPadding = 16.0;
  static const double cardMargin = 8.0;
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = 12.0;

  // Typography
  static const double titleFontSize = 18.0;
  static const double descriptionFontSize = 14.0;
  static const double rewardFontSize = 16.0;
  static const double captionFontSize = 12.0;

  // Sizes
  static const double avatarSize = 40.0;
  static const double smallAvatarSize = 32.0;
  static const double badgeHeight = 24.0;
  static const double buttonHeight = 48.0;

  // Animation
  static const Duration cardAnimationDuration = Duration(milliseconds: 300);
  static const Duration buttonAnimationDuration = Duration(milliseconds: 200);
}

// Task Sample Data
class TaskSampleData {
  static const List<Map<String, dynamic>> sampleTasks = [
    {
      'id': '1',
      'title': 'Help with Grocery Shopping',
      'description': 'Need help picking up groceries from the local supermarket. Items include fresh vegetables, dairy products, and household essentials.',
      'category': 'Shopping',
      'location': 'London, UK',
      'reward': 25.0,
      'postedBy': 'Sarah Johnson',
      'postedTime': '2 hours ago',
      'status': TaskStatus.open,
      'dateRequired': '2024-01-15',
      'timeRequired': '14:00',
    },
    {
      'id': '2',
      'title': 'Pet Sitting for Weekend',
      'description': 'Looking for someone to take care of my cat while I\'m away for the weekend. Need feeding, litter box cleaning, and some playtime.',
      'category': 'Household',
      'location': 'Manchester, UK',
      'reward': 40.0,
      'postedBy': 'Mike Wilson',
      'postedTime': '1 day ago',
      'status': TaskStatus.assigned,
      'dateRequired': '2024-01-20',
      'timeRequired': '09:00',
    },
    {
      'id': '3',
      'title': 'Computer Setup Assistance',
      'description': 'Need help setting up a new laptop and installing essential software. Basic computer knowledge required.',
      'category': 'Technology',
      'location': 'Birmingham, UK',
      'reward': 35.0,
      'postedBy': 'Emma Davis',
      'postedTime': '3 hours ago',
      'status': TaskStatus.open,
      'dateRequired': '2024-01-16',
      'timeRequired': '16:00',
    },
  ];
} 