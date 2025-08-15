import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../constants/ui_constants.dart';
import '../../../constants/myColors.dart';
import '../../../model/task_models/task_model.dart';
import '../../../model/authentication_models/user_model.dart';
import '../../../controller/providers/task_providers/task_provider.dart';
import '../../../services/notification_helper.dart';
import '../../components/shared_components/user_avatar.dart';

class TaskDeliveryViewScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDeliveryViewScreen({super.key, required this.task});

  @override
  State<TaskDeliveryViewScreen> createState() => _TaskDeliveryViewScreenState();
}

class _TaskDeliveryViewScreenState extends State<TaskDeliveryViewScreen> {

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        // Get the updated task from the provider
        final updatedTask = taskProvider.userTasks.firstWhere(
          (t) => t.id == widget.task.id,
          orElse: () => widget.task,
        );
        
        return Scaffold(
          backgroundColor: scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Task Delivery'),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(UIConstants.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task info card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(UIConstants.spacingL),
                  decoration: WidgetStyles.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task Details',
                        style: TextStyles.heading3,
                      ),
                      const SizedBox(height: UIConstants.spacingM),
                      Text(
                        updatedTask.title,
                        style: TextStyles.body1.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: UIConstants.spacingS),
                      Text(
                        updatedTask.description,
                        style: TextStyles.body2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: UIConstants.spacingM),
                      Row(
                        children: [
                          Icon(
                            Icons.monetization_on,
                            size: UIConstants.iconSizeS,
                            color: secondaryColor,
                          ),
                          const SizedBox(width: UIConstants.spacingS),
                          Text(
                            '£${updatedTask.reward.toStringAsFixed(0)}',
                            style: TextStyles.body1.copyWith(
                              color: secondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: UIConstants.spacingL),
                
                // Delivery status
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(UIConstants.spacingM),
                  decoration: BoxDecoration(
                    color: successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                    border: Border.all(color: successColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: successColor,
                        size: UIConstants.iconSizeM,
                      ),
                      const SizedBox(width: UIConstants.spacingS),
                      Expanded(
                        child: Text(
                          'Task has been delivered successfully',
                          style: TextStyles.body2.copyWith(
                            color: successColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: UIConstants.spacingL),
                
                // Doer information
                if (updatedTask.doerId != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(UIConstants.spacingL),
                    decoration: WidgetStyles.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivered by',
                          style: TextStyles.heading3,
                        ),
                        const SizedBox(height: UIConstants.spacingM),
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(updatedTask.doerId)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox(
                                height: 60,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return Text('User not found', style: TextStyles.body1);
                            }
                            final user = UserModel.fromFirestore(snapshot.data!);
                            return Row(
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
                                        style: TextStyles.body1.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
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
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: UIConstants.spacingL),
                ],
                
                // Delivery message
                if (updatedTask.deliveryProof.isNotEmpty && updatedTask.deliveryProof['message'] != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(UIConstants.spacingL),
                    decoration: WidgetStyles.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Message',
                          style: TextStyles.heading3,
                        ),
                        const SizedBox(height: UIConstants.spacingM),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(UIConstants.spacingM),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                          ),
                          child: Text(
                            updatedTask.deliveryProof['message'] as String,
                            style: TextStyles.body2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: UIConstants.spacingL),
                ],
                
                // Delivery proof image
                if (updatedTask.deliveryProof.isNotEmpty && updatedTask.deliveryProof['url'] != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(UIConstants.spacingL),
                    decoration: WidgetStyles.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Proof',
                          style: TextStyles.heading3,
                        ),
                        const SizedBox(height: UIConstants.spacingM),
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                            child: Image.network(
                              updatedTask.deliveryProof['url'] as String,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        size: UIConstants.iconSizeL,
                                        color: textSecondaryColor,
                                      ),
                                      const SizedBox(height: UIConstants.spacingS),
                                      Text(
                                        'Failed to load image',
                                        style: TextStyles.body2.copyWith(
                                          color: textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: UIConstants.spacingL),
                ],
                
                // Delivery timestamp
                if (updatedTask.deliveryProof.isNotEmpty && updatedTask.deliveryProof['uploadedAt'] != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(UIConstants.spacingM),
                    decoration: BoxDecoration(
                      color: infoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: infoColor,
                          size: UIConstants.iconSizeM,
                        ),
                        const SizedBox(width: UIConstants.spacingS),
                        Expanded(
                          child: Text(
                            'Delivered ${_formatTimeAgo((updatedTask.deliveryProof['uploadedAt'] as Timestamp).toDate())}',
                            style: TextStyles.body2.copyWith(color: infoColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Action buttons for poster
                if (updatedTask.status == TaskStatus.delivered) ...[
                  const SizedBox(height: UIConstants.spacingL),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(UIConstants.spacingL),
                    decoration: WidgetStyles.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Actions',
                          style: TextStyles.heading3,
                        ),
                        const SizedBox(height: UIConstants.spacingM),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: UIConstants.buttonHeightM,
                                child: OutlinedButton(
                                  onPressed: () => _showRejectDeliveryDialog(context),
                                  style: WidgetStyles.secondaryButtonStyle.copyWith(
                                    foregroundColor: WidgetStatePropertyAll(errorColor),
                                    side: WidgetStatePropertyAll(BorderSide(color: errorColor)),
                                  ),
                                  child: const Text('Reject'),
                                ),
                              ),
                            ),
                            const SizedBox(width: UIConstants.spacingM),
                            Expanded(
                              child: SizedBox(
                                height: UIConstants.buttonHeightM,
                                child: ElevatedButton(
                                  onPressed: () => _showAcceptDeliveryDialog(context),
                                  style: WidgetStyles.primaryButtonStyle,
                                  child: const Text('Accept'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Review section (only show after delivery is accepted)
                if (updatedTask.status == TaskStatus.completed) ...[
                  const SizedBox(height: UIConstants.spacingL),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(UIConstants.spacingL),
                    decoration: WidgetStyles.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review Doer',
                          style: TextStyles.heading3,
                        ),
                        const SizedBox(height: UIConstants.spacingM),
                        if (updatedTask.ratingByPoster != null) ...[
                          // Show existing review
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(UIConstants.spacingM),
                            decoration: BoxDecoration(
                              color: successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ...List.generate(5, (index) => Icon(
                                      index < (updatedTask.ratingByPoster ?? 0).round() 
                                        ? Icons.star 
                                        : Icons.star_border,
                                      color: accentColor,
                                      size: UIConstants.iconSizeM,
                                    )),
                                    const SizedBox(width: UIConstants.spacingS),
                                    Text(
                                      '${updatedTask.ratingByPoster!.toStringAsFixed(1)}/5.0',
                                      style: TextStyles.body2.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (updatedTask.reviewMessageByPoster != null) ...[
                                  const SizedBox(height: UIConstants.spacingM),
                                  Text(
                                    updatedTask.reviewMessageByPoster!,
                                    style: TextStyles.body2,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ] else ...[
                          // Show review button
                          SizedBox(
                            width: double.infinity,
                            height: UIConstants.buttonHeightM,
                            child: OutlinedButton(
                              onPressed: () => _showReviewDialog(context),
                              style: WidgetStyles.secondaryButtonStyle,
                              child: const Text('Leave Review'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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

  // Show reject delivery confirmation dialog
  void _showRejectDeliveryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Delivery'),
        content: const Text(
          'Are you sure you want to reject this delivery? The task will be returned to the doer for re-delivery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _rejectDelivery();
            },
            style: WidgetStyles.primaryButtonStyle.copyWith(
              backgroundColor: WidgetStatePropertyAll(errorColor),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  // Show accept delivery confirmation dialog
  void _showAcceptDeliveryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Delivery'),
        content: const Text(
          'Are you sure you want to accept this delivery? This will complete the task and you can leave a review for the doer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _acceptDelivery();
            },
            style: WidgetStyles.primaryButtonStyle,
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  // Show review dialog
  void _showReviewDialog(BuildContext context) {
    double rating = 0;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Leave Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rate the doer:'),
              const SizedBox(height: UIConstants.spacingM),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => GestureDetector(
                  onTap: () => setState(() => rating = index + 1),
                  child: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: accentColor,
                    size: UIConstants.iconSizeL,
                  ),
                )),
              ),
              const SizedBox(height: UIConstants.spacingM),
              TextField(
                controller: reviewController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Write your review (optional)...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: rating > 0 ? () async {
                Navigator.of(context).pop();
                await _submitReview(rating, reviewController.text.trim());
              } : null,
              style: WidgetStyles.primaryButtonStyle,
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }

  // Reject delivery
  Future<void> _rejectDelivery() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final success = await taskProvider.rejectDelivery(widget.task.id);
    
    if (success && mounted) {
      // Send notification to the doer about the rejected delivery
      if (widget.task.doerId != null) {
        await NotificationHelper.notifyDeliveryRejected(
          doerId: widget.task.doerId!,
          taskTitle: widget.task.title,
          taskId: widget.task.id,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery rejected. Task returned to doer.'),
          backgroundColor: successColor,
        ),
      );
      Navigator.of(context).pop(); // Go back to previous screen
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taskProvider.errorMessage ?? 'Failed to reject delivery'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  // Accept delivery
  Future<void> _acceptDelivery() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final success = await taskProvider.acceptDelivery(widget.task.id);
    
    if (success && mounted) {
      // Send notification to the doer about the accepted delivery
      if (widget.task.doerId != null) {
        await NotificationHelper.notifyDeliveryAccepted(
          doerId: widget.task.doerId!,
          taskTitle: widget.task.title,
          taskId: widget.task.id,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery accepted! You can now leave a review.'),
          backgroundColor: successColor,
        ),
      );
      // The UI will automatically update due to the Consumer wrapper
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taskProvider.errorMessage ?? 'Failed to accept delivery'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  // Submit review
  Future<void> _submitReview(double rating, String reviewMessage) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final success = await taskProvider.submitReview(widget.task.id, rating, reviewMessage);
    
    if (success && mounted) {
      // Send notification to the doer about the review
      if (widget.task.doerId != null) {
        await NotificationHelper.notifyTaskReview(
          taskOwnerId: widget.task.doerId!,
          taskTitle: widget.task.title,
          taskId: widget.task.id,
          rating: rating,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully!'),
          backgroundColor: successColor,
        ),
      );
      // The UI will automatically update due to the Consumer wrapper
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taskProvider.errorMessage ?? 'Failed to submit review'),
          backgroundColor: errorColor,
        ),
      );
    }
  }
} 