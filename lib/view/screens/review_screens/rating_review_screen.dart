import 'package:flutter/material.dart';
import '../../../constants/review_constants.dart';
import '../../../constants/ui_constants.dart';
import '../../../constants/myColors.dart';
import '../../components/shared_components/loading_components.dart';

class RatingReviewScreen extends StatefulWidget {
  final String taskTitle;
  final String userName;

  const RatingReviewScreen({
    super.key,
    required this.taskTitle,
    required this.userName,
  });

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> {
  final TextEditingController _reviewController = TextEditingController();
  double _overallRating = 0.0;
  Map<String, double> _categoryRatings = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize category ratings
    for (final category in ReviewCategories.categories) {
      _categoryRatings[category] = 0.0;
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _updateOverallRating() {
    final ratings = _categoryRatings.values.where((rating) => rating > 0).toList();
    if (ratings.isNotEmpty) {
      setState(() {
        _overallRating = ratings.reduce((a, b) => a + b) / ratings.length;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_overallRating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a rating before submitting'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSubmitting = false;
    });

    if (mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Review Submitted!'),
        content: const Text(
          'Thank you for your review. It has been submitted successfully.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: WidgetStyles.primaryButtonStyle,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Rate & Review'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _overallRating > 0 && !_isSubmitting ? _submitReview : null,
            child: const Text('Submit'),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isSubmitting,
        message: 'Submitting review...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(UIConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(UIConstants.spacingL),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(UIConstants.borderRadiusL),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate your experience',
                      style: TextStyles.heading2,
                    ),
                    const SizedBox(height: UIConstants.spacingM),
                    Text(
                      'Task: ${widget.taskTitle}',
                      style: TextStyles.body1.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: UIConstants.spacingS),
                    Text(
                      'User: ${widget.userName}',
                      style: TextStyles.body2.copyWith(
                        color: textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: UIConstants.spacingL),

              // Overall Rating
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(UIConstants.spacingL),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(UIConstants.borderRadiusL),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Rating',
                      style: TextStyles.heading3,
                    ),
                    const SizedBox(height: UIConstants.spacingM),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _overallRating = index + 1.0;
                              });
                            },
                            child: Icon(
                              index < _overallRating ? Icons.star : Icons.star_border,
                              size: ReviewUIConstants.starSize,
                              color: ReviewUIConstants.starColor,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: UIConstants.spacingM),
                    Center(
                      child: Text(
                        _overallRating > 0 ? '${_overallRating.toStringAsFixed(1)} stars' : 'Tap to rate',
                        style: TextStyles.body1.copyWith(
                          color: _overallRating > 0 ? ReviewUIConstants.ratingTextColor : textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: UIConstants.spacingL),

              // Category Ratings
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(UIConstants.spacingL),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(UIConstants.borderRadiusL),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate by Category (Optional)',
                      style: TextStyles.heading3,
                    ),
                    const SizedBox(height: UIConstants.spacingM),
                    ...ReviewCategories.categories.map((category) {
                      return _buildCategoryRating(category);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: UIConstants.spacingL),

              // Review Text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(UIConstants.spacingL),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(UIConstants.borderRadiusL),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Write a Review (Optional)',
                      style: TextStyles.heading3,
                    ),
                    const SizedBox(height: UIConstants.spacingM),
                    TextField(
                      controller: _reviewController,
                      maxLines: 5,
                      decoration: WidgetStyles.inputDecoration.copyWith(
                        hintText: 'Share your experience with this user...',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: UIConstants.spacingL),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: UIConstants.buttonHeightL,
                child: ElevatedButton(
                  onPressed: _overallRating > 0 && !_isSubmitting ? _submitReview : null,
                  style: WidgetStyles.primaryButtonStyle.copyWith(
                    backgroundColor: WidgetStatePropertyAll(
                      _overallRating > 0 ? buttonPrimaryColor : buttonDisabledColor,
                    ),
                  ),
                  child: const Text(
                    'Submit Review',
                    style: TextStyle(fontSize: UIConstants.fontSizeL),
                  ),
                ),
              ),
              const SizedBox(height: UIConstants.spacingM),

              // Skip Button
              SizedBox(
                width: double.infinity,
                height: UIConstants.buttonHeightM,
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () {
                    Navigator.of(context).pop();
                  },
                  style: WidgetStyles.secondaryButtonStyle,
                  child: const Text('Skip Review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRating(String category) {
    final rating = _categoryRatings[category] ?? 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ReviewCategories.categoryIcons[category],
                size: UIConstants.iconSizeS,
                color: primaryColor,
              ),
              const SizedBox(width: UIConstants.spacingS),
              Expanded(
                child: Text(
                  category,
                  style: TextStyles.body1.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (rating > 0)
                Text(
                  '${rating.toStringAsFixed(1)}',
                  style: TextStyles.caption.copyWith(
                    color: ReviewUIConstants.ratingTextColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: UIConstants.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _categoryRatings[category] = index + 1.0;
                    _updateOverallRating();
                  });
                },
                child: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  size: ReviewUIConstants.smallStarSize,
                  color: ReviewUIConstants.starColor,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
} 