import 'package:flutter/material.dart';
import '../../../constants/task_constants.dart';
import '../../../constants/ui_constants.dart';
import '../../../constants/myColors.dart';
import '../../../model/task_models/task_model.dart';
import 'user_avatar.dart';
import 'status_badge.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String description;
  final String location;
  final double reward;
  final String postedBy;
  final String postedTime;
  final TaskStatus? status;
  final String category;
  final VoidCallback? onTap;
  final VoidCallback? onViewDetails;

  const TaskCard({
    super.key,
    required this.title,
    required this.description,
    required this.location,
    required this.reward,
    required this.postedBy,
    required this.postedTime,
    this.status,
    required this.category,
    this.onTap,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
     // margin: const EdgeInsets.all(6),
      elevation: TaskUIConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TaskUIConstants.cardBorderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TaskUIConstants.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with category and status
              Row(
                children: [
                  Icon(
                    TaskCategories.categoryIcons[category] ?? Icons.more_horiz,
                    size: UIConstants.iconSizeS,
                    color: primaryColor,
                  ),
                  const SizedBox(width: UIConstants.spacingS),
                  Expanded(
                    child: Text(
                      category,
                      style: TextStyles.caption.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: UIConstants.spacingS),
                  if (status != null) StatusBadge(status: status!),
                ],
              ),
              const SizedBox(height: UIConstants.spacingM),

              // Task title
              Text(
                title,
                style: TextStyles.heading3.copyWith(
                  fontSize: TaskUIConstants.titleFontSize,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: UIConstants.spacingS),

              // Description
              Text(
                description,
                style: TextStyles.body2.copyWith(
                  fontSize: TaskUIConstants.descriptionFontSize,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: UIConstants.spacingM),

              // Location
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: UIConstants.iconSizeS,
                    color: textSecondaryColor,
                  ),
                  const SizedBox(width: UIConstants.spacingS),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: UIConstants.spacingM),

              // Footer with poster info and reward
              Row(
                children: [
                  // Poster info
                  Expanded(
                    child: Row(
                      children: [
                        UserAvatar(
                          size: TaskUIConstants.smallAvatarSize,
                          userName: postedBy,
                        ),
                        const SizedBox(width: UIConstants.spacingS),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                postedBy,
                                style: TextStyles.body2.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                postedTime,
                                style: TextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Reward (only show for non-mutual tasks)
                  if (reward > 0) ...[
                    const SizedBox(width: UIConstants.spacingM),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: UIConstants.spacingM,
                        vertical: UIConstants.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                      ),
                      child: Text(
                        '£${reward.toStringAsFixed(0)}',
                        style: TextStyles.body1.copyWith(
                          fontSize: TaskUIConstants.rewardFontSize,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                    ),
                  ],
                  
                  // Mutual label (only show for mutual tasks)
                  if (reward == 0) ...[
                    const SizedBox(width: UIConstants.spacingM),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: UIConstants.spacingM,
                        vertical: UIConstants.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            size: UIConstants.iconSizeS,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: UIConstants.spacingS),
                          Text(
                            'Mutual',
                            style: TextStyles.body2.copyWith(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: UIConstants.spacingM),

              // View Details button
              if (onViewDetails != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onViewDetails,
                    style: WidgetStyles.primaryButtonStyle,
                    child: const Text('View Details'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 