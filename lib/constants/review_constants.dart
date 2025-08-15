import 'package:flutter/material.dart';
import 'myColors.dart';

// Review Categories
class ReviewCategories {
  static const List<String> categories = [
    'Communication',
    'Quality of Work',
    'Timeliness',
    'Professionalism',
    'Overall Experience',
  ];

  static const Map<String, IconData> categoryIcons = {
    'Communication': Icons.chat,
    'Quality of Work': Icons.work,
    'Timeliness': Icons.schedule,
    'Professionalism': Icons.person,
    'Overall Experience': Icons.star,
  };
}

// Review UI Constants
class ReviewUIConstants {
  // Spacing
  static const double cardPadding = 16.0;
  static const double cardMargin = 8.0;
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = 12.0;

  // Typography
  static const double titleFontSize = 18.0;
  static const double reviewTextFontSize = 14.0;
  static const double ratingFontSize = 16.0;
  static const double captionFontSize = 12.0;

  // Sizes
  static const double avatarSize = 48.0;
  static const double starSize = 24.0;
  static const double smallStarSize = 16.0;
  static const double ratingBarHeight = 40.0;

  // Colors
  static const Color starColor = accentColor;
  static const Color starEmptyColor = Color(0xFFE0E0E0);
  static const Color ratingTextColor = textPrimaryColor;

  // Animation
  static const Duration starAnimationDuration = Duration(milliseconds: 200);
  static const Duration cardAnimationDuration = Duration(milliseconds: 300);
}

// Review Sample Data
class ReviewSampleData {
  static const List<Map<String, dynamic>> sampleReviews = [
    {
      'id': '1',
      'userName': 'Sarah Johnson',
      'userAvatar': null,
      'rating': 5.0,
      'reviewText': 'Excellent service! Very professional and completed the task exactly as requested. Highly recommend!',
      'datePosted': '2 days ago',
      'taskTitle': 'Help with Grocery Shopping',
      'category': 'Shopping',
    },
    {
      'id': '2',
      'userName': 'Mike Wilson',
      'userAvatar': null,
      'rating': 4.0,
      'reviewText': 'Great communication and timely completion. Would definitely work with again.',
      'datePosted': '1 week ago',
      'taskTitle': 'Pet Sitting for Weekend',
      'category': 'Household',
    },
    {
      'id': '3',
      'userName': 'Emma Davis',
      'userAvatar': null,
      'rating': 5.0,
      'reviewText': 'Amazing work! Very knowledgeable and patient. Set up everything perfectly.',
      'datePosted': '3 days ago',
      'taskTitle': 'Computer Setup Assistance',
      'category': 'Technology',
    },
  ];

  static const Map<String, double> averageRatings = {
    'Communication': 4.5,
    'Quality of Work': 4.8,
    'Timeliness': 4.3,
    'Professionalism': 4.7,
    'Overall Experience': 4.6,
  };
} 