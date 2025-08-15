import 'package:flutter/material.dart';
import '../../../constants/review_constants.dart';
import '../../../constants/ui_constants.dart';
import '../../../constants/myColors.dart';
import '../../components/shared_components/user_avatar.dart';
import '../../components/shared_components/loading_components.dart';

class ReviewsReceivedScreen extends StatefulWidget {
  const ReviewsReceivedScreen({super.key});

  @override
  State<ReviewsReceivedScreen> createState() => _ReviewsReceivedScreenState();
}

class _ReviewsReceivedScreenState extends State<ReviewsReceivedScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _filteredReviews = [];
  String _selectedFilter = 'All';
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _filteredReviews = List.from(ReviewSampleData.sampleReviews);
      _calculateAverageRating();
      _isLoading = false;
    });
  }

  void _calculateAverageRating() {
    if (_filteredReviews.isNotEmpty) {
      final totalRating = _filteredReviews.fold<double>(
        0.0,
        (sum, review) => sum + (review['rating'] as double),
      );
      _averageRating = totalRating / _filteredReviews.length;
    }
  }

  void _filterReviews() {
    setState(() {
      if (_selectedFilter == 'All') {
        _filteredReviews = List.from(ReviewSampleData.sampleReviews);
      } else {
        _filteredReviews = ReviewSampleData.sampleReviews.where((review) {
          return review['rating'].toString() == _selectedFilter;
        }).toList();
      }
      _calculateAverageRating();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Reviews Received'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Overall rating header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(UIConstants.spacingL),
            color: Colors.white,
            child: Column(
              children: [
                Text(
                  'Overall Rating',
                  style: TextStyles.heading3,
                ),
                const SizedBox(height: UIConstants.spacingM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: TextStyles.heading1.copyWith(
                        color: ReviewUIConstants.starColor,
                      ),
                    ),
                    const SizedBox(width: UIConstants.spacingS),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < _averageRating.floor() 
                                  ? Icons.star 
                                  : (index < _averageRating ? Icons.star_half : Icons.star_border),
                              size: ReviewUIConstants.smallStarSize,
                              color: ReviewUIConstants.starColor,
                            );
                          }),
                        ),
                        Text(
                          '${_filteredReviews.length} reviews',
                          style: TextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: UIConstants.spacingM),
                
                // Rating distribution
                if (_filteredReviews.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: UIConstants.spacingM),
                  ...List.generate(5, (index) {
                    final rating = 5 - index;
                    final count = _filteredReviews.where((r) => r['rating'] == rating).length;
                    final percentage = _filteredReviews.isNotEmpty 
                        ? (count / _filteredReviews.length) * 100 
                        : 0.0;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: UIConstants.spacingS),
                      child: Row(
                        children: [
                          Text(
                            '$rating',
                            style: TextStyles.caption,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(width: UIConstants.spacingS),
                          Icon(
                            Icons.star,
                            size: UIConstants.iconSizeS,
                            color: ReviewUIConstants.starColor,
                          ),
                          const SizedBox(width: UIConstants.spacingS),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ReviewUIConstants.starColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: UIConstants.spacingS),
                          Text(
                            '$count',
                            style: TextStyles.caption,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          // Reviews list
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredReviews.isEmpty
                    ? _buildEmptyState()
                    : _buildReviewsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(UIConstants.spacingM),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: UIConstants.spacingM),
          padding: const EdgeInsets.all(UIConstants.spacingM),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar skeleton
                  Container(
                    width: ReviewUIConstants.avatarSize,
                    height: ReviewUIConstants.avatarSize,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: UIConstants.spacingM),
                  // Content skeleton
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(UIConstants.borderRadiusS),
                          ),
                        ),
                        const SizedBox(height: UIConstants.spacingS),
                        Container(
                          height: 14,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(UIConstants.borderRadiusS),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: UIConstants.spacingM),
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(UIConstants.borderRadiusS),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_border,
            size: UIConstants.iconSizeXL,
            color: textSecondaryColor,
          ),
          const SizedBox(height: UIConstants.spacingM),
          Text(
            'No reviews yet',
            style: TextStyles.heading3.copyWith(color: textSecondaryColor),
          ),
          const SizedBox(height: UIConstants.spacingS),
          Text(
            'Complete tasks to receive reviews from other users',
            style: TextStyles.body2.copyWith(color: textSecondaryColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return PullToRefreshIndicator(
      onRefresh: _loadReviews,
      child: ListView.builder(
        padding: const EdgeInsets.all(UIConstants.spacingM),
        itemCount: _filteredReviews.length,
        itemBuilder: (context, index) {
          final review = _filteredReviews[index];
          return _buildReviewCard(review);
        },
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.spacingM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 2.0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and rating
            Row(
              children: [
                UserAvatar(
                  size: ReviewUIConstants.avatarSize,
                  userName: review['userName'],
                ),
                const SizedBox(width: UIConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review['userName'],
                        style: TextStyles.body1.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: UIConstants.spacingS),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < review['rating'] ? Icons.star : Icons.star_border,
                              size: ReviewUIConstants.smallStarSize,
                              color: ReviewUIConstants.starColor,
                            );
                          }),
                          const SizedBox(width: UIConstants.spacingS),
                          Text(
                            '${review['rating'].toStringAsFixed(1)}',
                            style: TextStyles.caption.copyWith(
                              color: ReviewUIConstants.ratingTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  review['datePosted'],
                  style: TextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: UIConstants.spacingM),

            // Task context
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacingS,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusS),
              ),
              child: Text(
                review['taskTitle'],
                style: TextStyles.caption.copyWith(
                  color: primaryColor,
                  fontSize: UIConstants.fontSizeXS,
                ),
              ),
            ),
            const SizedBox(height: UIConstants.spacingM),

            // Review text
            Text(
              review['reviewText'],
              style: TextStyles.body2.copyWith(
                fontSize: ReviewUIConstants.reviewTextFontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Reviews'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('All Reviews'),
              value: 'All',
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.of(context).pop();
                _filterReviews();
              },
            ),
            ...List.generate(5, (index) {
              final rating = 5 - index;
              return RadioListTile<String>(
                title: Row(
                  children: [
                    Text('$rating Stars'),
                    const SizedBox(width: UIConstants.spacingS),
                    ...List.generate(rating, (starIndex) {
                      return Icon(
                        Icons.star,
                        size: UIConstants.iconSizeS,
                        color: ReviewUIConstants.starColor,
                      );
                    }),
                  ],
                ),
                value: rating.toString(),
                groupValue: _selectedFilter,
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  Navigator.of(context).pop();
                  _filterReviews();
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
} 