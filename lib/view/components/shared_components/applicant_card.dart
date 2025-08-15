import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants/ui_constants.dart';
import '../../../constants/myColors.dart';
import '../../../model/authentication_models/user_model.dart';
import 'user_avatar.dart';

class ApplicantCard extends StatelessWidget {
  final Map<String, dynamic> applicant;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ApplicantCard({
    super.key,
    required this.applicant,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final userId = applicant['userId'] as String;
    final message = applicant['message'] as String? ?? '';
    final appliedAt = applicant['appliedAt'] as Timestamp?;

    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.spacingM),
      decoration: WidgetStyles.cardDecoration,
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeletonCard();
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Padding(
              padding: EdgeInsets.all(UIConstants.spacingL),
              child: Text('User not found'),
            );
          }

          final user = UserModel.fromFirestore(snapshot.data!);

          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusL),
            child: Padding(
              padding: const EdgeInsets.all(UIConstants.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      UserAvatar(
                        size: UIConstants.iconSizeXL,
                        userName: user.displayName ?? 'User',
                        imageUrl: user.photoURL,
                      ),
                      const SizedBox(width: UIConstants.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName ?? 'User',
                              style: TextStyles.heading3,
                            ),
                            const SizedBox(height: UIConstants.spacingS),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: UIConstants.iconSizeS,
                                  color: accentColor,
                                ),
                                const SizedBox(width: UIConstants.spacingS),
                                Text(
                                  '${(user.ratings['asDoer'] ?? 0).toStringAsFixed(1)} (${user.numberofReviewsAsDoer} reviews)',
                                  style: TextStyles.caption,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: UIConstants.spacingM),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(UIConstants.spacingM),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                      ),
                      child: Text(
                        message,
                        style: TextStyles.body2,
                      ),
                    ),
                  ],
                  if (appliedAt != null) ...[
                    const SizedBox(height: UIConstants.spacingM),
                    Text(
                      'Applied ${_formatTimeAgo(appliedAt.toDate())}',
                      style: TextStyles.caption,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Padding(
      padding: const EdgeInsets.all(UIConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Skeleton avatar
              Container(
                width: UIConstants.iconSizeXL,
                height: UIConstants.iconSizeXL,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: UIConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Skeleton name
                    Container(
                      height: 20,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: UIConstants.spacingS),
                    // Skeleton rating
                    Container(
                      height: 16,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              // Skeleton trailing widget
              if (trailing != null)
                Container(
                  height: UIConstants.buttonHeightM,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                  ),
                ),
            ],
          ),
          const SizedBox(height: UIConstants.spacingM),
          // Skeleton message
          Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: UIConstants.spacingS),
          Container(
            height: 16,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: UIConstants.spacingM),
          // Skeleton timestamp
          Container(
            height: 14,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
} 