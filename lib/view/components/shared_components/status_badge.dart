import 'package:flutter/material.dart';
import '../../../constants/task_constants.dart';
import '../../../constants/ui_constants.dart';
import '../../../model/task_models/task_model.dart';

class StatusBadge extends StatelessWidget {
  final TaskStatus status;
  final double? size;

  const StatusBadge({
    super.key,
    required this.status,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.spacingM,
        vertical: UIConstants.spacingS,
      ),
      decoration: BoxDecoration(
        color: TaskStatusColors.getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
        border: Border.all(
          color: TaskStatusColors.getStatusColor(status),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          TaskStatusColors.getStatusText(status),
          style: TextStyle(
            color: TaskStatusColors.getStatusColor(status),
            fontSize: UIConstants.fontSizeS,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
} 