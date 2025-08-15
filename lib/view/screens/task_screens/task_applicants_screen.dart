import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/ui_constants.dart';
import '../../../constants/myColors.dart';
import '../../../model/task_models/task_model.dart';
import '../../../controller/providers/task_providers/task_provider.dart';
import '../../../services/notification_helper.dart';
import '../../components/shared_components/loading_components.dart';
import '../../components/shared_components/applicant_card.dart';
import '../profile_screens/user_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskApplicantsScreen extends StatefulWidget {
  final TaskModel task;

  const TaskApplicantsScreen({super.key, required this.task});

  @override
  State<TaskApplicantsScreen> createState() => _TaskApplicantsScreenState();
}

class _TaskApplicantsScreenState extends State<TaskApplicantsScreen> {
  List<Map<String, dynamic>> _applicants = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _hiringUserId;

  @override
  void initState() {
    super.initState();
    _loadApplicants();
  }

  Future<void> _loadApplicants() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final applicants = await taskProvider.getTaskApplicants(widget.task.id);
      
      setState(() {
        _applicants = applicants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load applicants: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _hireApplicant(String applicantId) async {
    // Show confirmation dialog first
    final confirmed = await _showHireConfirmationDialog(applicantId);
    if (!confirmed) return;

    try {
      setState(() {
        _hiringUserId = applicantId;
      });

      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final success = await taskProvider.hireApplicant(widget.task.id, applicantId);
      
      if (success) {
        // Send notification to the hired applicant
        await NotificationHelper.notifyTaskHiring(
          hiredUserId: applicantId,
          taskTitle: widget.task.title,
          taskId: widget.task.id,
        );

        // Send notifications to all other applicants that they were not hired
        final notHiredUserIds = _applicants
            .where((applicant) => applicant['userId'] != applicantId)
            .map((applicant) => applicant['userId'] as String)
            .toList();

        if (notHiredUserIds.isNotEmpty) {
          await NotificationHelper.notifyTaskNotHired(
            notHiredUserIds: notHiredUserIds,
            taskTitle: widget.task.title,
            taskId: widget.task.id,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Applicant hired successfully!'),
            backgroundColor: successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(taskProvider.errorMessage ?? 'Failed to hire applicant'),
            backgroundColor: errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error hiring applicant: $e'),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      setState(() {
        _hiringUserId = null;
      });
    }
  }

  Future<bool> _showHireConfirmationDialog(String applicantId) async {
    // Get applicant name for the dialog
    String applicantName = 'this applicant';
    try {
      final applicant = _applicants.firstWhere((a) => a['userId'] == applicantId);
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(applicant['userId'])
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        applicantName = userData['displayName'] ?? 'this applicant';
      }
    } catch (e) {
      // If we can't get the name, use default
    }

    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Hiring'),
          content: Text(
            'Are you sure you want to hire $applicantName? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: WidgetStyles.primaryButtonStyle,
              child: const Text('Hire'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Applicants (${_applicants.length})'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplicants,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_applicants.isEmpty) {
      return _buildEmptyState();
    }

    return _buildApplicantsList();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: errorColor,
              ),
            ),
            const SizedBox(height: UIConstants.spacingL),
            Text(
              'Oops! Something went wrong',
              style: TextStyles.heading2.copyWith(color: textPrimaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.spacingM),
            Text(
              _errorMessage!,
              style: TextStyles.body2.copyWith(color: textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.spacingL),
            ElevatedButton.icon(
              onPressed: _loadApplicants,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: WidgetStyles.primaryButtonStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(UIConstants.spacingM),
      itemCount: 3, // Show 3 shimmer cards
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: UIConstants.spacingM),
          decoration: WidgetStyles.cardDecoration,
          child: Padding(
            padding: const EdgeInsets.all(UIConstants.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Shimmer avatar
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
                          // Shimmer name
                          Container(
                            height: 20,
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: UIConstants.spacingS),
                          // Shimmer rating
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
                    // Shimmer hire button
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
                // Shimmer message
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
                // Shimmer timestamp
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
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 70,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: UIConstants.spacingL),
            Text(
              'No applicants yet',
              style: TextStyles.heading2.copyWith(color: textPrimaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.spacingM),
            Text(
              'Your task hasn\'t received any applications yet.\nTry sharing it with your network or adjusting the details.',
              style: TextStyles.body2.copyWith(color: textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.spacingL),
            Container(
              padding: const EdgeInsets.all(UIConstants.spacingM),
              decoration: BoxDecoration(
                color: infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusL),
                border: Border.all(color: infoColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: infoColor,
                    size: UIConstants.iconSizeL,
                  ),
                  const SizedBox(height: UIConstants.spacingS),
                  Text(
                    'Tips to get more applicants:',
                    style: TextStyles.body2.copyWith(
                      color: infoColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: UIConstants.spacingS),
                  Text(
                    '• Share on social media\n• Adjust the reward amount\n• Add more details to description\n• Check your task visibility',
                    style: TextStyles.caption.copyWith(color: textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantsList() {
    return RefreshIndicator(
      onRefresh: _loadApplicants,
      child: ListView.builder(
        padding: const EdgeInsets.all(UIConstants.spacingM),
        itemCount: _applicants.length,
        itemBuilder: (context, index) {
          final applicant = _applicants[index];
          return _buildApplicantCard(applicant);
        },
      ),
    );
  }

  Widget _buildApplicantCard(Map<String, dynamic> applicant) {
    final userId = applicant['userId'] as String;
    final isHiring = _hiringUserId == userId;
    
    // Get the updated task from the provider
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final updatedTask = taskProvider.userTasks.firstWhere(
      (t) => t.id == widget.task.id,
      orElse: () => widget.task,
    );
    
    final isTaskAssigned = updatedTask.isAssigned;
    final isThisUserHired = updatedTask.doerId == userId;

    return ApplicantCard(
      applicant: applicant,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(userId: userId),
          ),
        );
      },
      trailing: _buildHireButton(userId, isHiring, isTaskAssigned, isThisUserHired),
    );
  }

  Widget _buildHireButton(String userId, bool isHiring, bool isTaskAssigned, bool isThisUserHired) {
    if (isThisUserHired) {
      // User is hired - show "Hired" with success color
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: UIConstants.spacingM,
          vertical: UIConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: successColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
        ),
        child: Text(
          'Hired',
          style: TextStyle(
            color: successColor,
            fontWeight: FontWeight.w500,
            fontSize: UIConstants.fontSizeS,
          ),
        ),
      );
    }

    if (isTaskAssigned) {
      // Task is assigned to someone else - show disabled "Hire" button
      return SizedBox(
        height: UIConstants.buttonHeightM,
        child: ElevatedButton(
          onPressed: null, // Disabled
          style: WidgetStyles.primaryButtonStyle.copyWith(
            backgroundColor: WidgetStatePropertyAll(buttonDisabledColor),
            foregroundColor: WidgetStatePropertyAll(buttonTextDisabledColor),
          ),
          child: const Text('Hire'),
        ),
      );
    }

    // Task is open - show hire button with loading state
    return SizedBox(
      height: UIConstants.buttonHeightM,
      child: ElevatedButton(
        onPressed: isHiring ? null : () => _hireApplicant(userId),
        style: WidgetStyles.primaryButtonStyle.copyWith(
          backgroundColor: WidgetStatePropertyAll(
            isHiring ? buttonDisabledColor : buttonPrimaryColor,
          ),
        ),
        child: isHiring
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text('Hire'),
      ),
    );
  }
} 