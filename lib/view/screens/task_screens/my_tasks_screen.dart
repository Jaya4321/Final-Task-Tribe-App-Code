import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_tribe_app/view/screens/task_screens/post_task_screen.dart';
import '../../../constants/task_constants.dart';
import '../../../constants/ui_constants.dart';
import '../../../constants/myColors.dart';
import '../../../model/task_models/task_model.dart';
import '../../../controller/providers/task_providers/task_provider.dart';
import '../../../controller/providers/authentication_providers/auth_provider.dart';
import '../../../services/notification_helper.dart';
import '../../components/shared_components/loading_components.dart';
import 'task_details_screen.dart';
import 'task_progress_screen.dart';
import 'task_applicants_screen.dart';
import 'task_delivery_screen.dart';
import 'task_delivery_view_screen.dart';
import 'mutual_task_management_screen.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    print('Debug: MyTasksScreen initState');
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Add listener for tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        print('Debug: Tab changing to index: ${_tabController.index}');
        _onTabChanged(_tabController.index);
      }
    });
    
    print('Debug: initState');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadTasks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    print('Debug: Tab changed to index: $index');
    if (index == 1) { // Accepted tab
      print('Debug: Loading accepted tasks on tab change');
      _loadAcceptedTasks();
    }
  }

  Future<void> _loadTasks() async {
    print('Debug: _loadTasks called');
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userData != null) {
      print('Debug: Loading tasks for user: ${authProvider.userData!.uid}');
      await taskProvider.loadUserTasks(authProvider.userData!.uid);
      await taskProvider.loadAcceptedTasks(authProvider.userData!.uid);
      print('Debug: Tasks loaded - User tasks: ${taskProvider.userTasks.length}, Accepted tasks: ${taskProvider.acceptedTasks.length}');
    } else {
      print('Debug: No user data available');
    }
  }

  Future<void> _loadAcceptedTasks() async {
    print('Debug: _loadAcceptedTasks called');
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userData != null) {
      print('Debug: Loading accepted tasks for user: ${authProvider.userData!.uid}');
      await taskProvider.loadAcceptedTasks(authProvider.userData!.uid);
      print('Debug: Accepted tasks loaded: ${taskProvider.acceptedTasks.length}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
          // Temporary debug button
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () async {
              print('Debug: Manual trigger of accepted tasks loading');
              await _loadAcceptedTasks();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: textSecondaryColor,
          indicatorColor: primaryColor,
          tabs: [
            Tab(
              child: Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.post_add),
                      const SizedBox(width: UIConstants.spacingS),
                      const Text('Posted'),
                      if (taskProvider.userTasks.isNotEmpty) ...[
                        const SizedBox(width: UIConstants.spacingS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(UIConstants.borderRadiusS),
                          ),
                          child: Text(
                            taskProvider.userTasks.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: UIConstants.fontSizeXS,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            Tab(
              child: Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment_turned_in),
                      const SizedBox(width: UIConstants.spacingS),
                      const Text('Accepted'),
                      if (taskProvider.acceptedTasks.isNotEmpty) ...[
                        const SizedBox(width: UIConstants.spacingS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: secondaryColor,
                            borderRadius: BorderRadius.circular(UIConstants.borderRadiusS),
                          ),
                          child: Text(
                            taskProvider.acceptedTasks.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: UIConstants.fontSizeXS,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostedTasksTab(),
          _buildAcceptedTasksTab(),
        ],
      ),
    );
  }

  Widget _buildPostedTasksTab() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        if (taskProvider.isLoading) {
          return _buildLoadingState();
        }

        if (taskProvider.errorMessage != null) {
          return _buildErrorState(taskProvider.errorMessage!);
        }

        if (taskProvider.userTasks.isEmpty) {
          return _buildEmptyPostedTasksState();
        }

        return _buildPostedTasksList(taskProvider.userTasks);
      },
    );
  }

  Widget _buildAcceptedTasksTab() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        if (taskProvider.isLoading) {
          return _buildLoadingState();
        }

        if (taskProvider.errorMessage != null) {
          return _buildErrorState(taskProvider.errorMessage!);
        }

        if (taskProvider.acceptedTasks.isEmpty) {
          return _buildEmptyAcceptedTasksState();
        }

        return _buildAcceptedTasksList(taskProvider.acceptedTasks);
      },
    );
  }

  Widget _buildLoadingState() {
    return const CenterLoading(
      message: 'Loading your tasks...',
      size: 40.0,
    );
  }

  Widget _buildErrorState(String errorMessage) {
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
              errorMessage,
              style: TextStyles.body2.copyWith(color: textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.spacingL),
            ElevatedButton.icon(
              onPressed: _loadTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: WidgetStyles.primaryButtonStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPostedTasksState() {
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
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.post_add,
                size: 60,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: UIConstants.spacingL),
            Text(
              'No tasks posted yet',
              style: TextStyles.heading2.copyWith(color: textPrimaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.spacingM),
            Text(
              'Start helping others by posting your first task!',
              style: TextStyles.body2.copyWith(color: textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.spacingL),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PostTaskScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Post a Task'),
              style: WidgetStyles.primaryButtonStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAcceptedTasksState() {
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
                color: secondaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_turned_in,
                size: 60,
                color: secondaryColor,
              ),
            ),
            const SizedBox(height: UIConstants.spacingL),
            Text(
              'No accepted tasks yet',
              style: TextStyles.heading2.copyWith(color: textPrimaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.spacingM),
            Text(
              'Browse available tasks and start helping others in your community!',
              style: TextStyles.body2.copyWith(color: textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.spacingL),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/task-feed');
              },
              icon: const Icon(Icons.search),
              label: const Text('Browse Tasks'),
              style: WidgetStyles.primaryButtonStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostedTasksList(List<TaskModel> tasks) {
    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(UIConstants.spacingM),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return _buildPostedTaskCard(task);
        },
      ),
    );
  }

  Widget _buildAcceptedTasksList(List<TaskModel> tasks) {
    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(UIConstants.spacingM),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return _buildAcceptedTaskCard(task);
        },
      ),
    );
  }

  Widget _buildPostedTaskCard(TaskModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.spacingM),
      decoration: WidgetStyles.cardDecoration,
      child: InkWell(
        onTap: () => _onTaskTap(task),
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusL),
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyles.heading3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: UIConstants.spacingM),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: UIConstants.spacingM,
                      vertical: UIConstants.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: TaskStatusColors.getStatusColor(task.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                    ),
                    child: Text(
                      TaskStatusColors.getStatusText(task.status),
                      style: TextStyle(
                        color: TaskStatusColors.getStatusColor(task.status),
                        fontWeight: FontWeight.w500,
                        fontSize: UIConstants.fontSizeS,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: UIConstants.spacingM),
              Text(
                task.description,
                style: TextStyles.body2,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: UIConstants.spacingL),
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
                      task.location,
                      style: TextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Show 'Mutual Task' label for mutual tasks, price for regular tasks
                  if (task.isMutual) ...[
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
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            size: UIConstants.iconSizeS,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Mutual Task',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                              fontSize: UIConstants.fontSizeS,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: UIConstants.spacingM),
                    Icon(
                      Icons.monetization_on,
                      size: UIConstants.iconSizeS,
                      color: secondaryColor,
                    ),
                    const SizedBox(width: UIConstants.spacingS),
                    Text(
                      '£${task.reward.toStringAsFixed(0)}',
                      style: TextStyles.body1.copyWith(
                        color: secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: UIConstants.spacingM),
              Row(
                children: [
                  Icon(
                    Icons.category,
                    size: UIConstants.iconSizeS,
                    color: textSecondaryColor,
                  ),
                  const SizedBox(width: UIConstants.spacingS),
                  Text(
                    task.category,
                    style: TextStyles.caption,
                  ),
                  const Spacer(),
                  Text(
                    _formatTimeAgo(task.createdAt),
                    style: TextStyles.caption,
                  ),
                ],
              ),
              // Applicants section
              const SizedBox(height: UIConstants.spacingM),
              if (task.applicants.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UIConstants.spacingM,
                    vertical: UIConstants.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: infoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people,
                        size: UIConstants.iconSizeS,
                        color: infoColor,
                      ),
                      const SizedBox(width: UIConstants.spacingS),
                      Text(
                        '${task.applicants.length} applicant${task.applicants.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: infoColor,
                          fontWeight: FontWeight.w500,
                          fontSize: UIConstants.fontSizeS,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: UIConstants.spacingM),
                SizedBox(
                  width: double.infinity,
                  height: UIConstants.buttonHeightM,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TaskApplicantsScreen(task: task),
                        ),
                      );
                    },
                    style: WidgetStyles.secondaryButtonStyle,
                    child: const Text('View Applicants', style: TextStyle(fontSize: 12),),
                  ),
                ),
              ] else if (!task.isMutual) ...[
                // Only show 'No applicants yet' for non-mutual tasks
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UIConstants.spacingM,
                    vertical: UIConstants.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: textSecondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                    border: Border.all(
                      color: textSecondaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: UIConstants.iconSizeS,
                        color: textSecondaryColor,
                      ),
                      const SizedBox(width: UIConstants.spacingS),
                      Text(
                        'No applicants yet',
                        style: TextStyle(
                          color: textSecondaryColor,
                          fontWeight: FontWeight.w500,
                          fontSize: UIConstants.fontSizeS,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Always show the orange info message (unless mutual proposal comes and it disappears as before)
              if (!task.applicants.isNotEmpty && (!task.isMutual || (task.isMutual && !task.hasPendingMutualProposals()))) ...[
                const SizedBox(height: UIConstants.spacingM),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UIConstants.spacingM,
                    vertical: UIConstants.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: UIConstants.iconSizeS,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: UIConstants.spacingS),
                      Expanded(
                        child: Text(
                          'Your task is visible to others. Applicants will appear here when they apply.',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: UIConstants.fontSizeS,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Show View Delivery button for delivered/completed tasks (applicants or mutual)
              if ((task.status == TaskStatus.delivered || task.status == TaskStatus.completed) && (task.applicants.isNotEmpty || task.isMutual)) ...[
                const SizedBox(height: UIConstants.spacingM),
                SizedBox(
                  width: double.infinity,
                  height: UIConstants.buttonHeightM,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TaskDeliveryViewScreen(task: task),
                        ),
                      );
                    },
                    style: WidgetStyles.secondaryButtonStyle.copyWith(
                      foregroundColor: WidgetStatePropertyAll(successColor),
                      side: WidgetStatePropertyAll(BorderSide(color: successColor)),
                    ),
                    child: const Text('View Delivery', style: TextStyle(fontSize: 12),),
                  ),
                ),
              ],
              // Always show for mutual tasks (moved outside applicants block)
              if (task.isMutual) ...[
                const SizedBox(height: UIConstants.spacingM),
                Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: UIConstants.buttonHeightM,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => MutualTaskManagementScreen(task: task),
                            ),
                          );
                        },
                        style: WidgetStyles.secondaryButtonStyle.copyWith(
                          foregroundColor: WidgetStatePropertyAll(Colors.blue),
                          side: WidgetStatePropertyAll(BorderSide(color: Colors.blue)),
                        ),
                        child: Builder(
                          builder: (context) {
                            final hasAcceptedProposal = task.getAcceptedMutualProposal() != null;
                            final hasPendingProposals = task.hasPendingMutualProposals();
                            if (!hasAcceptedProposal && hasPendingProposals) {
                              return Text(
                                'View Mutual Proposals (${task.getPendingMutualProposals().length} Pending)',
                                style: const TextStyle(fontSize: 12),
                              );
                            } else {
                              return const Text(
                                'View Mutual Proposals',
                                style: TextStyle(fontSize: 12),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final hasAcceptedProposal = task.getAcceptedMutualProposal() != null;
                        final hasPendingProposals = task.hasPendingMutualProposals();
                        if (!hasAcceptedProposal && hasPendingProposals) {
                          return Positioned(
                            top: 4,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                task.getPendingMutualProposals().length.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcceptedTaskCard(TaskModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.spacingM),
      decoration: WidgetStyles.cardDecoration,
      child: InkWell(
        onTap: () => _onTaskTap(task),
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusL),
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyles.heading3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: UIConstants.spacingM),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: UIConstants.spacingM,
                      vertical: UIConstants.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: TaskStatusColors.getStatusColor(task.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                    ),
                    child: Text(
                      TaskStatusColors.getStatusText(task.status),
                      style: TextStyle(
                        color: TaskStatusColors.getStatusColor(task.status),
                        fontWeight: FontWeight.w500,
                        fontSize: UIConstants.fontSizeS,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: UIConstants.spacingM),
              Text(
                task.description,
                style: TextStyles.body2,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: UIConstants.spacingL),
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
                      task.location,
                      style: TextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Show 'Mutual Task' label for mutual tasks, price for regular tasks
                  if (task.isMutual) ...[
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
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            size: UIConstants.iconSizeS,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Mutual Task',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                              fontSize: UIConstants.fontSizeS,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: UIConstants.spacingM),
                    Icon(
                      Icons.monetization_on,
                      size: UIConstants.iconSizeS,
                      color: secondaryColor,
                    ),
                    const SizedBox(width: UIConstants.spacingS),
                    Text(
                      '£${task.reward.toStringAsFixed(0)}',
                      style: TextStyles.body1.copyWith(
                        color: secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: UIConstants.spacingM),
              Row(
                children: [
                  Icon(
                    Icons.category,
                    size: UIConstants.iconSizeS,
                    color: textSecondaryColor,
                  ),
                  const SizedBox(width: UIConstants.spacingS),
                  Text(
                    task.category,
                    style: TextStyles.caption,
                  ),
                  const Spacer(),
                  Text(
                    _formatTimeAgo(task.createdAt),
                    style: TextStyles.caption,
                  ),
                ],
              ),
              if (task.acceptedAt != null) ...[
                const SizedBox(height: UIConstants.spacingM),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UIConstants.spacingM,
                    vertical: UIConstants.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: UIConstants.iconSizeS,
                        color: successColor,
                      ),
                      const SizedBox(width: UIConstants.spacingS),
                      Text(
                        'Accepted ${_formatTimeAgo(task.acceptedAt!)}',
                        style: TextStyle(
                          color: successColor,
                          fontWeight: FontWeight.w500,
                          fontSize: UIConstants.fontSizeS,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (task.status == TaskStatus.assigned || task.status == TaskStatus.delivered) ...[
                const SizedBox(height: UIConstants.spacingM),
                GestureDetector(
                  onTap: () {}, // Prevent tap from bubbling up to card
                  child: SizedBox(
                    width: double.infinity,
                    height: UIConstants.buttonHeightM,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TaskDeliveryScreen(task: task),
                          ),
                        );
                      },
                      style: WidgetStyles.secondaryButtonStyle,
                      child: Text(
                        task.status == TaskStatus.delivered ? 'Deliver Again' : 'Deliver',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
              // Review section for completed tasks
              if (task.status == TaskStatus.completed) ...[
                const SizedBox(height: UIConstants.spacingM),
                if (task.hasDoerReview) ...[
                  // Show review submitted message
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
                            'Review submitted successfully!',
                            style: TextStyles.body2.copyWith(
                              color: successColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Show review button
                  GestureDetector(
                    onTap: () {}, // Prevent tap from bubbling up to card
                    child: SizedBox(
                      width: double.infinity,
                      height: UIConstants.buttonHeightM,
                      child: OutlinedButton(
                        onPressed: () => _showDoerReviewDialog(context, task),
                        style: WidgetStyles.secondaryButtonStyle.copyWith(
                          foregroundColor: WidgetStatePropertyAll(accentColor),
                          side: WidgetStatePropertyAll(BorderSide(color: accentColor)),
                        ),
                        child: const Text(
                          'Leave Review',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onTaskTap(TaskModel task) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.userData;
    
    // Refresh task data before navigating
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      if (currentUser != null) {
        // Refresh both user tasks and accepted tasks to ensure we have the latest data
        await taskProvider.loadUserTasks(currentUser.uid);
        await taskProvider.loadAcceptedTasks(currentUser.uid);
      }
    });
    
    // Always navigate to task details screen when tapping on the card
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TaskDetailsScreen(task: task),
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

  // Show doer review dialog
  void _showDoerReviewDialog(BuildContext context, TaskModel task) {
    double rating = 0;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Leave Review for Poster'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rate the poster:'),
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
                await _submitDoerReview(task, rating, reviewController.text.trim());
              } : null,
              style: WidgetStyles.primaryButtonStyle,
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }

  // Submit doer review
  Future<void> _submitDoerReview(TaskModel task, double rating, String reviewMessage) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final success = await taskProvider.submitDoerReview(task.id, rating, reviewMessage);
    
    if (success && mounted) {
      // Send notification to the poster about the review
      await NotificationHelper.notifyTaskReview(
        taskOwnerId: task.posterId,
        taskTitle: task.title,
        taskId: task.id,
        rating: rating,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully!'),
          backgroundColor: successColor,
        ),
      );
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