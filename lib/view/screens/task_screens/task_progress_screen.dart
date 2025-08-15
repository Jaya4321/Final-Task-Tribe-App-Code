import 'package:flutter/material.dart';
import '../../../constants/task_constants.dart';
import '../../../constants/ui_constants.dart';
import '../../../constants/myColors.dart';
import '../../../model/task_models/task_model.dart';
import '../../components/shared_components/loading_components.dart';

class TaskProgressScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const TaskProgressScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskProgressScreen> createState() => _TaskProgressScreenState();
}

class _TaskProgressScreenState extends State<TaskProgressScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Task Progress'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Updating progress...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(UIConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task information
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
                      widget.task['title'],
                      style: TextStyles.heading2,
                    ),
                    const SizedBox(height: UIConstants.spacingM),
                    Text(
                      widget.task['description'],
                      style: TextStyles.body1,
                    ),
                    const SizedBox(height: UIConstants.spacingL),
                    Row(
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: secondaryColor,
                          size: UIConstants.iconSizeM,
                        ),
                        const SizedBox(width: UIConstants.spacingS),
                        Text(
                          '£${widget.task['reward'].toStringAsFixed(0)}',
                          style: TextStyles.heading3.copyWith(
                            color: secondaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: UIConstants.spacingM,
                            vertical: UIConstants.spacingS,
                          ),
                          decoration: BoxDecoration(
                            color: TaskStatusColors.getStatusColor(widget.task['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                          ),
                          child: Text(
                            TaskStatusColors.getStatusText(widget.task['status']),
                            style: TextStyle(
                              color: TaskStatusColors.getStatusColor(widget.task['status']),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: UIConstants.spacingL),

              // Progress stepper
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
                      'Progress Timeline',
                      style: TextStyles.heading3,
                    ),
                    const SizedBox(height: UIConstants.spacingL),
                    _buildProgressStepper(),
                  ],
                ),
              ),
              const SizedBox(height: UIConstants.spacingL),

              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStepper() {
    final steps = [
      {
        'title': 'Task Created',
        'description': 'Task was posted and is now visible to users',
        'icon': Icons.add_task,
        'completed': true,
        'date': '2024-01-15 10:30',
      },
      {
        'title': 'Task Accepted',
        'description': 'Task has been accepted by a user',
        'icon': Icons.check_circle,
        'completed': widget.task['status'] != TaskStatus.open,
        'date': widget.task['status'] != TaskStatus.open ? '2024-01-15 14:20' : null,
      },
      {
        'title': 'In Progress',
        'description': 'Task is currently being worked on',
        'icon': Icons.work,
        'completed': widget.task['status'] == TaskStatus.assigned || widget.task['status'] == TaskStatus.completed,
        'date': widget.task['status'] == TaskStatus.assigned || widget.task['status'] == TaskStatus.completed ? '2024-01-16 09:15' : null,
      },
      {
        'title': 'Completed',
        'description': 'Task has been completed successfully',
        'icon': Icons.done_all,
        'completed': widget.task['status'] == TaskStatus.completed,
        'date': widget.task['status'] == TaskStatus.completed ? '2024-01-17 16:45' : null,
      },
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step icon and line
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (step['completed'] as bool) ? successColor : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step['icon'] as IconData,
                    color: (step['completed'] as bool) ? Colors.white : textSecondaryColor,
                    size: UIConstants.iconSizeM,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 60,
                    color: (step['completed'] as bool) ? successColor : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: UIConstants.spacingM),
            
            // Step content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['title'] as String,
                    style: TextStyles.body1.copyWith(
                      fontWeight: FontWeight.w500,
                      color: (step['completed'] as bool) ? textPrimaryColor : textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: UIConstants.spacingS),
                  Text(
                    step['description'] as String,
                    style: TextStyles.body2.copyWith(
                      color: textSecondaryColor,
                    ),
                  ),
                  if (step['date'] != null) ...[
                    const SizedBox(height: UIConstants.spacingS),
                    Text(
                      step['date'] as String,
                      style: TextStyles.caption,
                    ),
                  ],
                  if (!isLast) const SizedBox(height: UIConstants.spacingL),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (widget.task['status'] == TaskStatus.assigned) ...[
          SizedBox(
            width: double.infinity,
            height: UIConstants.buttonHeightL,
            child: ElevatedButton(
              onPressed: () {
                _markTaskComplete();
              },
              style: WidgetStyles.primaryButtonStyle,
              child: const Text(
                'Mark as Completed',
                style: TextStyle(fontSize: UIConstants.fontSizeL),
              ),
            ),
          ),
          const SizedBox(height: UIConstants.spacingM),
        ],
        
        if (widget.task['status'] == TaskStatus.completed) ...[
          SizedBox(
            width: double.infinity,
            height: UIConstants.buttonHeightL,
            child: ElevatedButton(
              onPressed: () {
                _navigateToReview();
              },
              style: WidgetStyles.primaryButtonStyle,
              child: const Text(
                'Rate & Review',
                style: TextStyle(fontSize: UIConstants.fontSizeL),
              ),
            ),
          ),
          const SizedBox(height: UIConstants.spacingM),
        ],
        
        SizedBox(
          width: double.infinity,
          height: UIConstants.buttonHeightM,
          child: OutlinedButton(
            onPressed: () {
              _contactUser();
            },
            style: WidgetStyles.secondaryButtonStyle,
            child: const Text('Contact'),
          ),
        ),
      ],
    );
  }

  void _markTaskComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Task Complete'),
        content: const Text(
          'Are you sure you want to mark this task as completed? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateTaskStatus(TaskStatus.completed);
            },
            style: WidgetStyles.primaryButtonStyle,
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _updateTaskStatus(TaskStatus status) {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        widget.task['status'] = status;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task ${TaskStatusColors.getStatusText(status).toLowerCase()} successfully!'),
        ),
      );
    });
  }

  void _navigateToReview() {
    // Navigate to review screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to review screen'),
      ),
    );
  }

  void _contactUser() {
    // Navigate to chat or contact screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to chat screen'),
      ),
    );
  }
} 