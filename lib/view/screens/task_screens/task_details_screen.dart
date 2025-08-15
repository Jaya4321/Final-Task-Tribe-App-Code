import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../constants/task_constants.dart';
import '../../../constants/ui_constants.dart';
import '../../../constants/myColors.dart';
import '../../components/shared_components/user_avatar.dart';
import '../../components/shared_components/status_badge.dart';
import '../../../model/task_models/task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../model/authentication_models/user_model.dart';
import 'package:provider/provider.dart';
import '../../../controller/providers/authentication_providers/auth_provider.dart';
import '../../../view/screens/profile_screens/user_profile_screen.dart';
import '../../../utils/chat_helpers.dart';
import '../../../controller/providers/task_providers/task_provider.dart';
import '../../../services/notification_helper.dart';
import 'mutual_task_proposal_screen.dart';

class TaskDetailsScreen extends StatelessWidget {
  final TaskModel task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          // Get the updated task from the provider - check both userTasks and acceptedTasks
          TaskModel updatedTask = task;
          
          // First check in userTasks (posted tasks)
          try {
            updatedTask = taskProvider.userTasks.firstWhere(
              (t) => t.id == task.id,
              orElse: () => task,
            );
          } catch (e) {
            // If not found in userTasks, check in acceptedTasks
            try {
              updatedTask = taskProvider.acceptedTasks.firstWhere(
                (t) => t.id == task.id,
                orElse: () => task,
              );
            } catch (e) {
              // If not found in either, use the original task
              updatedTask = task;
            }
          }
          
          // Check if task was deleted (not found in any list)
          final taskExists = taskProvider.userTasks.any((t) => t.id == task.id) ||
                           taskProvider.acceptedTasks.any((t) => t.id == task.id) ||
                           taskProvider.tasks.any((t) => t.id == task.id);
          
          // If task was deleted, navigate back
          if (!taskExists) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted && Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }
            });
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          return Scaffold(
            backgroundColor: scaffoldBackgroundColor,
            appBar: AppBar(
              title: const Text('Task Details'),
              backgroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.report),
                  onPressed: () {
                    _showReportDialog(context);
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(UIConstants.spacingL),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category and status
                        Row(
                          children: [
                            Icon(
                              TaskCategories.categoryIcons[updatedTask.category] ?? Icons.more_horiz,
                              size: UIConstants.iconSizeM,
                              color: primaryColor,
                            ),
                            const SizedBox(width: UIConstants.spacingS),
                            Text(
                              updatedTask.category,
                              style: TextStyles.body2.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            StatusBadge(status: updatedTask.status),
                          ],
                        ),
                        const SizedBox(height: UIConstants.spacingM),
          
                        // Task title
                        Text(
                          updatedTask.title,
                          style: TextStyles.heading1.copyWith(
                            fontSize: UIConstants.fontSizeXXL,
                          ),
                        ),
                        const SizedBox(height: UIConstants.spacingS),
          
                        // Posted time
                        Text(
                          'Posted ${_formatTimeAgo(updatedTask.createdAt)}',
                          style: TextStyles.caption,
                        ),
                      ],
                    ),
                  ),
          
                  const SizedBox(height: UIConstants.spacingM),
          
                  // Task content
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(UIConstants.spacingL),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyles.heading3,
                        ),
                        const SizedBox(height: UIConstants.spacingM),
                        Text(
                          updatedTask.description,
                          style: TextStyles.body1,
                        ),
                        const SizedBox(height: UIConstants.spacingL),
          
                        // Additional Requirements (only show if not null)
                        if (updatedTask.additionalRequirements != null && updatedTask.additionalRequirements!.isNotEmpty) ...[
                          Text(
                            'Additional Requirements',
                            style: TextStyles.heading3,
                          ),
                          const SizedBox(height: UIConstants.spacingM),
                          Text(
                            updatedTask.additionalRequirements!,
                            style: TextStyles.body1,
                          ),
                          const SizedBox(height: UIConstants.spacingL),
                        ],
          
                        // Location
                        _buildInfoRow(
                          icon: Icons.location_on,
                          title: 'Location',
                          value: updatedTask.location,
                        ),
                        const SizedBox(height: UIConstants.spacingM),
          
                        // Date and time
                        _buildInfoRow(
                          icon: Icons.schedule,
                          title: 'Date & Time',
                          value: '${updatedTask.date} at ${updatedTask.time}',
                        ),
                        const SizedBox(height: UIConstants.spacingL),
          
                        // Reward section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(UIConstants.spacingM),
                          decoration: BoxDecoration(
                            color: secondaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                updatedTask.isMutual ? Icons.swap_horiz : Icons.monetization_on,
                                color: updatedTask.isMutual ? Colors.blue : secondaryColor,
                                size: UIConstants.iconSizeL,
                              ),
                              const SizedBox(width: UIConstants.spacingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      updatedTask.isMutual ? 'Exchange Task' : 'Reward',
                                      style: TextStyles.caption,
                                    ),
                                    Text(
                                      updatedTask.isMutual 
                                          ? 'No payment - task exchange'
                                          : '£${updatedTask.reward.toStringAsFixed(0)}',
                                      style: TextStyles.heading2.copyWith(
                                        color: updatedTask.isMutual ? Colors.blue : secondaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // NEW: Mutual task status indicator
                        if (updatedTask.isMutual) ...[
                          const SizedBox(height: UIConstants.spacingM),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(UIConstants.spacingM),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[700],
                                  size: UIConstants.iconSizeS,
                                ),
                                const SizedBox(width: UIConstants.spacingS),
                                Expanded(
                                  child: Text(
                                    'This is a mutual task exchange. You can propose one of your own tasks in return.',
                                    style: TextStyles.body2.copyWith(
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          
                  const SizedBox(height: UIConstants.spacingM),
          
                  // Poster information
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(UIConstants.spacingL),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Posted by',
                          style: TextStyles.heading3,
                        ),
                        const SizedBox(height: UIConstants.spacingM),
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(updatedTask.posterId)
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
                            return InkWell(
                              borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => UserProfileScreen(userId: user.uid),
                                  ),
                                );
                              },
                              child: Row(
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
                                              '${(user.ratings['asPoster'] ?? 0).toStringAsFixed(1)} (${user.numberofReviewsAsPoster} reviews)',
                                              style: TextStyles.caption,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: UIConstants.spacingS),
                                        Text(
                                          'Member since ${_formatMonthYear(user.createdAt)}',
                                          style: TextStyles.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => UserProfileScreen(userId: user.uid),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Doer information (if task is assigned)
                  if (updatedTask.doerId != null) ...[
                    const SizedBox(height: UIConstants.spacingM),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(UIConstants.spacingL),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assigned to',
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
                              return InkWell(
                                borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => UserProfileScreen(userId: user.uid),
                                    ),
                                  );
                                },
                                child: Row(
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
                                          const SizedBox(height: UIConstants.spacingS),
                                          Text(
                                            'Member since ${_formatMonthYear(user.createdAt)}',
                                            style: TextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.arrow_forward_ios),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => UserProfileScreen(userId: user.uid),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Mutual Reviews Section (only show when both reviews are submitted)
                  if (updatedTask.canShowReviews) ...[
                    const SizedBox(height: UIConstants.spacingM),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(UIConstants.spacingL),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mutual Reviews',
                            style: TextStyles.heading3,
                          ),
                          const SizedBox(height: UIConstants.spacingM),
                          
                          // Poster's review of doer
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(UIConstants.spacingM),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                              border: Border.all(color: primaryColor.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: primaryColor,
                                      size: UIConstants.iconSizeM,
                                    ),
                                    const SizedBox(width: UIConstants.spacingS),
                                    Text(
                                      'Poster\'s Review of Doer',
                                      style: TextStyles.body1.copyWith(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: UIConstants.spacingS),
                                Row(
                                  children: [
                                    ...List.generate(5, (index) => Icon(
                                      index < (updatedTask.ratingByPoster ?? 0).round() 
                                        ? Icons.star 
                                        : Icons.star_border,
                                      color: accentColor,
                                      size: UIConstants.iconSizeS,
                                    )),
                                    const SizedBox(width: UIConstants.spacingS),
                                    Text(
                                      '${updatedTask.ratingByPoster!.toStringAsFixed(1)}/5.0',
                                      style: TextStyles.caption.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (updatedTask.reviewMessageByPoster != null) ...[
                                  const SizedBox(height: UIConstants.spacingS),
                                  Text(
                                    updatedTask.reviewMessageByPoster!,
                                    style: TextStyles.caption,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: UIConstants.spacingM),
                          
                          // Doer's review of poster
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(UIConstants.spacingM),
                            decoration: BoxDecoration(
                              color: secondaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                              border: Border.all(color: secondaryColor.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      color: secondaryColor,
                                      size: UIConstants.iconSizeM,
                                    ),
                                    const SizedBox(width: UIConstants.spacingS),
                                    Text(
                                      'Doer\'s Review of Poster',
                                      style: TextStyles.body1.copyWith(
                                        color: secondaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: UIConstants.spacingS),
                                Row(
                                  children: [
                                    ...List.generate(5, (index) => Icon(
                                      index < (updatedTask.ratingByDoer ?? 0).round() 
                                        ? Icons.star 
                                        : Icons.star_border,
                                      color: accentColor,
                                      size: UIConstants.iconSizeS,
                                    )),
                                    const SizedBox(width: UIConstants.spacingS),
                                    Text(
                                      '${updatedTask.ratingByDoer!.toStringAsFixed(1)}/5.0',
                                      style: TextStyles.caption.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (updatedTask.reviewMessageByDoer != null) ...[
                                  const SizedBox(height: UIConstants.spacingS),
                                  Text(
                                    updatedTask.reviewMessageByDoer!,
                                    style: TextStyles.caption,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
          
                  const SizedBox(height: UIConstants.spacingL),
          
                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.all(UIConstants.spacingL),
                    child: Consumer2<AuthProvider, TaskProvider>(
                      builder: (context, authProvider, taskProvider, child) {
                        final currentUser = authProvider.userData;
                        print('DEBUG: AuthProvider state - isAuthenticated: ${authProvider.isAuthenticated}, userData: ${currentUser?.uid}');
                        
                        // Get the updated task from the provider to ensure we have the latest state
                        TaskModel updatedTask = task;
                        try {
                          updatedTask = taskProvider.tasks.firstWhere(
                            (t) => t.id == task.id,
                            orElse: () => task,
                          );
                        } catch (e) {
                          // If not found in tasks, use the original task
                          updatedTask = task;
                        }
                        
                        final isPoster = currentUser != null && currentUser.uid == updatedTask.posterId;
                        final hasApplied = currentUser != null && updatedTask.hasApplied(currentUser.uid);
                        final canProposeMutual = currentUser != null && updatedTask.canProposeMutual(currentUser.uid);
                        
                        print('DEBUG: Task details - isPoster: $isPoster, hasApplied: $hasApplied, currentUser: ${currentUser?.uid}, posterId: ${updatedTask.posterId}');
                        
                        if (isPoster) {
                          return _buildPosterManagementOptions(context, updatedTask, currentUser);
                        }
                        
                        return Column(
                          children: [
                            // NEW: Different buttons for mutual vs regular tasks
                            if (updatedTask.isMutual) ...[
                              // Mutual task buttons
                              SizedBox(
                                width: double.infinity,
                                height: UIConstants.buttonHeightL,
                                child: ElevatedButton(
                                  onPressed: canProposeMutual ? () {
                                    print('DEBUG: Propose mutual task button pressed');
                                    if (currentUser != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MutualTaskProposalScreen(
                                            targetTask: updatedTask,
                                          ),
                                        ),
                                      );
                                    }
                                  } : null,
                                  style: WidgetStyles.primaryButtonStyle.copyWith(
                                    backgroundColor: WidgetStatePropertyAll(
                                      canProposeMutual ? Colors.blue : buttonDisabledColor,
                                    ),
                                  ),
                                  child: Text(
                                    canProposeMutual ? 'Propose Mutual Task' : _getMutualProposalButtonText(updatedTask, currentUser?.uid, context),
                                    style: const TextStyle(fontSize: UIConstants.fontSizeL),
                                  ),
                                ),
                              ),
                            ] else ...[
                              // Regular task buttons
                              SizedBox(
                                width: double.infinity,
                                height: UIConstants.buttonHeightL,
                                child: ElevatedButton(
                                  onPressed: hasApplied ? null : () {
                                    print('DEBUG: Apply button pressed - currentUser: ${currentUser?.uid}');
                                    if (currentUser != null) {
                                      _showApplyTaskDialog(context, currentUser.uid);
                                    } else {
                                      print('DEBUG: No current user, showing sign in message');
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please sign in to apply for tasks'),
                                          backgroundColor: errorColor,
                                        ),
                                      );
                                    }
                                  },
                                  style: WidgetStyles.primaryButtonStyle.copyWith(
                                    backgroundColor: WidgetStatePropertyAll(
                                      hasApplied ? buttonDisabledColor : buttonPrimaryColor,
                                    ),
                                  ),
                                  child: Text(
                                    hasApplied ? 'Applied' : 'Apply',
                                    style: const TextStyle(fontSize: UIConstants.fontSizeL),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: UIConstants.spacingM),
                            SizedBox(
                              width: double.infinity,
                              height: UIConstants.buttonHeightM,
                              child: OutlinedButton(
                                onPressed: () {
                                  // Contact poster using chat functionality
                                  ChatHelpers.handleContactPosterButton(
                                    context: context,
                                    posterId: updatedTask.posterId,
                                    taskTitle: updatedTask.title,
                                  );
                                },
                                style: WidgetStyles.secondaryButtonStyle,
                                child: const Text('Contact Poster'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: UIConstants.iconSizeM,
          color: textSecondaryColor,
        ),
        const SizedBox(width: UIConstants.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyles.caption,
              ),
              Text(
                value,
                style: TextStyles.body1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAcceptTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Task'),
        content: const Text(
          'Are you sure you want to accept this task? You will be responsible for completing it on time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showSuccessDialog(context);
            },
            style: WidgetStyles.primaryButtonStyle,
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Task Accepted!'),
        content: const Text(
          'You have successfully accepted the task. The poster will be notified.',
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

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Task'),
        content: const Text(
          'Are you sure you want to report this task? This will be reviewed by our team.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task reported successfully'),
                ),
              );
            },
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(errorColor),
            ),
            child: const Text('Report'),
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

  // Helper to format "Member since"
  String _formatMonthYear(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  // Show apply dialog
  void _showApplyTaskDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply for Task'),
        content: const Text('Are you sure you want to apply for this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              BuildContext? dialogContext;
              // Show loading dialog (do NOT await)
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) {
                  dialogContext = ctx;
                  return Dialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SpinKitSpinningLines(color: primaryColor, size: 32.0),
                          const SizedBox(height: 16),
                          const Text('Applying for task...'),
                        ],
                      ),
                    ),
                  );
                },
              );
              try {
                print('DEBUG: Starting task application...');
                print('DEBUG: Original task ID: ${task.id}');
                final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                
                // Get the updated task from the provider to ensure we have the correct ID
                final updatedTask = taskProvider.tasks.firstWhere(
                  (t) => t.id == task.id,
                  orElse: () => task,
                );
                
                print('DEBUG: Updated task ID: ${updatedTask.id}');
                print('DEBUG: User ID: $userId');
                
                if (updatedTask.id == null || updatedTask.id!.isEmpty) {
                  throw Exception('Task ID is null or empty');
                }
                
                                                final success = await taskProvider.applyForTask(updatedTask.id!, userId);
                                print('DEBUG: Task application result: $success');
                                
                                if (success) {
                                  print('DEBUG: Application successful, showing snackbar...');
                                  
                                  // Send notification to task poster about the application
                                  await NotificationHelper.notifyTaskApplication(
                                    taskOwnerId: updatedTask.posterId,
                                    taskTitle: updatedTask.title,
                                    taskId: updatedTask.id,
                                    applicantId: userId,
                                  );
                                  
                                  // Refresh the task data to ensure UI updates
                                  await taskProvider.loadTasks();
                                  
                                  // Show success snackbar using dialogContext (which is still valid)
                                  try {
                                    ScaffoldMessenger.of(dialogContext!).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Applied for post successfully',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: successColor,
                                        duration: const Duration(seconds: 3),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        margin: const EdgeInsets.all(16),
                                        elevation: 8,
                                      ),
                                    );
                                    print('DEBUG: Snackbar shown successfully');
                                  } catch (e) {
                                    print('DEBUG: Failed to show snackbar: $e');
                                  }
                                  
                                  // Close loading dialog
                                  if (dialogContext != null && Navigator.canPop(dialogContext!)) {
                                    Navigator.of(dialogContext!).pop();
                                  }
                                  
                                  // Navigate back after a short delay
                                  await Future.delayed(const Duration(milliseconds: 1000));
                                  if (context.mounted && Navigator.canPop(context)) {
                                    Navigator.of(context).pop();
                                  }
                                } else {
                  // Close loading dialog first
                  if (dialogContext != null && Navigator.canPop(dialogContext!)) {
                    Navigator.of(dialogContext!).pop();
                  }
                  
                  // Show error message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(taskProvider.errorMessage ?? 'Failed to apply for task'),
                        backgroundColor: errorColor,
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                        elevation: 8,
                      ),
                    );
                  }
                }
              } catch (e) {
                print('DEBUG: Error in task application: $e');
                
                // Close loading dialog first
                if (dialogContext != null && Navigator.canPop(dialogContext!)) {
                  Navigator.of(dialogContext!).pop();
                }
                
                // Show error message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error applying for task: $e'),
                      backgroundColor: errorColor,
                      duration: const Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                      elevation: 8,
                    ),
                  );
                }
              }
            },
            style: WidgetStyles.primaryButtonStyle,
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  // Helper method to get the appropriate button text for mutual task proposals
  String _getMutualProposalButtonText(TaskModel task, String? userId, BuildContext context) {
    if (userId == null) return 'Proposed';
    
    final proposalStatus = task.getUserProposalStatus(userId);
    switch (proposalStatus) {
      case MutualStatus.pending:
        return 'Proposal Pending';
      case MutualStatus.accepted:
        return 'Proposal Accepted';
      case MutualStatus.rejected:
        // Check if user has any available tasks to propose with
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        final userTasks = taskProvider.mutualTasks.where((t) => 
            t.isOpen && t.posterId == userId).toList();
        final hasAvailableTasks = task.hasAvailableTasksToPropose(userId, userTasks);
        return hasAvailableTasks ? 'Propose Different Task' : 'No Available Tasks';
      case MutualStatus.completed:
        return 'Exchange Completed';
      default:
        return 'Propose Mutual Task';
    }
  }

  Widget _buildPosterManagementOptions(BuildContext context, TaskModel task, UserModel? currentUser) {
    return Column(
      children: [
        // Only show delete button if task can be deleted (not assigned to anyone)
        if (currentUser != null && task.canDelete(currentUser.uid)) ...[
          SizedBox(
            width: double.infinity,
            height: UIConstants.buttonHeightL,
            child: ElevatedButton(
              onPressed: () {
                // Delete task
                _showDeleteTaskDialog(context, task);
              },
              style: WidgetStyles.primaryButtonStyle.copyWith(
                backgroundColor: WidgetStatePropertyAll(errorColor),
              ),
              child: const Text('Delete Task'),
            ),
          ),
          const SizedBox(height: UIConstants.spacingM),
        ],
        SizedBox(
          width: double.infinity,
          height: UIConstants.buttonHeightM,
          child: OutlinedButton(
            onPressed: () {
              // Contact poster using chat functionality
              ChatHelpers.handleContactPosterButton(
                context: context,
                posterId: task.posterId,
                taskTitle: task.title,
              );
            },
            style: WidgetStyles.secondaryButtonStyle,
            child: const Text('Contact Poster'),
          ),
        ),
      ],
    );
  }

  void _showDeleteTaskDialog(BuildContext context, TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text(
          'Are you sure you want to delete this task? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              BuildContext? dialogContext;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) {
                  dialogContext = ctx;
                  return Dialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SpinKitSpinningLines(color: errorColor, size: 32.0),
                          const SizedBox(height: 16),
                          const Text('Deleting task...'),
                        ],
                      ),
                    ),
                  );
                },
              );
              try {
                final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                
                // Find the task from userTasks since this is a posted task
                final updatedTask = taskProvider.userTasks.firstWhere(
                  (t) => t.id == task.id,
                  orElse: () => task,
                );
                
                if (updatedTask.id == null || updatedTask.id!.isEmpty) {
                  throw Exception('Task ID is null or empty');
                }
                
                final success = await taskProvider.deleteTask(updatedTask.id!);
                print('DEBUG: Task deletion result: $success');
                
                if (success) {
                  // Close loading dialog
                  if (dialogContext != null && Navigator.canPop(dialogContext!)) {
                    Navigator.of(dialogContext!).pop();
                  }
                  
                  // Show success message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Task deleted successfully'),
                        backgroundColor: successColor,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                        elevation: 8,
                      ),
                    );
                  }
                  
                  // Navigate back to previous screen
                  if (context.mounted && Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }
                } else {
                  // Close loading dialog
                  if (dialogContext != null && Navigator.canPop(dialogContext!)) {
                    Navigator.of(dialogContext!).pop();
                  }
                  
                  // Show error message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(taskProvider.errorMessage ?? 'Failed to delete task'),
                        backgroundColor: errorColor,
                        duration: Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: EdgeInsets.all(16),
                        elevation: 8,
                      ),
                    );
                  }
                }
              } catch (e) {
                print('DEBUG: Error in task deletion: $e');
                
                // Close loading dialog
                if (dialogContext != null && Navigator.canPop(dialogContext!)) {
                  Navigator.of(dialogContext!).pop();
                }
                
                // Show error message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting task: $e'),
                      backgroundColor: errorColor,
                      duration: Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: EdgeInsets.all(16),
                      elevation: 8,
                    ),
                  );
                }
              }
            },
            style: WidgetStyles.primaryButtonStyle,
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 