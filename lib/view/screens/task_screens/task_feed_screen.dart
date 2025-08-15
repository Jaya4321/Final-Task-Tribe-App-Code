import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../constants/task_constants.dart';
import '../../../constants/ui_constants.dart';
import '../../../constants/myColors.dart';
import '../../../model/task_models/task_model.dart';
import '../../../model/authentication_models/user_model.dart';
import '../../../controller/providers/task_providers/task_provider.dart';
import '../../../controller/providers/authentication_providers/auth_provider.dart';
import '../../components/shared_components/task_card.dart';
import '../../components/shared_components/loading_components.dart';
import 'task_details_screen.dart';
import 'post_task_screen.dart';

class TaskFeedScreen extends StatefulWidget {
  const TaskFeedScreen({super.key});

  @override
  State<TaskFeedScreen> createState() => _TaskFeedScreenState();
}

class _TaskFeedScreenState extends State<TaskFeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _showMutualTasks = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    await taskProvider.loadTasks();
  }

  void _filterTasks() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final searchQuery = _searchController.text.trim();
    final category = _selectedCategory == 'All' ? null : _selectedCategory;
    
    taskProvider.setSearchQuery(searchQuery.isEmpty ? null : searchQuery);
    taskProvider.setCategoryFilter(category);
    taskProvider.setMutualTaskFilter(_showMutualTasks);
  }

  // Helper function to fetch user display name
  Future<String> _getUserDisplayName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final user = UserModel.fromFirestore(userDoc);
        return user.displayName ?? 'User';
      }
      return 'User';
    } catch (e) {
      print('Error fetching user display name: $e');
      return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        body: RefreshIndicator(
          onRefresh: _loadTasks,
          child: Column(
            children: [
              // Search and filter bar
              Container(
                padding: const EdgeInsets.all(UIConstants.spacingM),
                color: Colors.white,
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterTasks();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                        ),
                      ),
                      onChanged: (value) => _filterTasks(),
                    ),
                    const SizedBox(height: UIConstants.spacingM),
                    
                    // Category filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip('All'),
                          ...TaskCategories.categories.map(_buildCategoryChip),
                        ],
                      ),
                    ),
                    
                    // NEW: Mutual task filter
                    const SizedBox(height: UIConstants.spacingM),
                    Container(
                      padding: const EdgeInsets.all(UIConstants.spacingS),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            color: Colors.blue[700],
                            size: UIConstants.iconSizeS,
                          ),
                          const SizedBox(width: UIConstants.spacingS),
                          Expanded(
                            child: Text(
                              'Show Mutual Tasks Only',
                              style: TextStyles.body2.copyWith(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Switch(
                            value: _showMutualTasks,
                            onChanged: (value) {
                              setState(() {
                                _showMutualTasks = value;
                              });
                              _filterTasks();
                            },
                            activeColor: Colors.blue[700],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          
              // Task list
              Expanded(
                child: Consumer<TaskProvider>(
                  builder: (context, taskProvider, child) {
                    if (taskProvider.isLoading) {
                      return _buildLoadingState();
                    }
          
                    if (taskProvider.errorMessage != null) {
                      return _buildErrorState(taskProvider.errorMessage!);
                    }
          
                    final tasks = taskProvider.filteredTasks;
                    
                    if (tasks.isEmpty) {
                      return _buildEmptyState();
                    }
          
                    return _buildTaskList(tasks);
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PostTaskScreen(),
              ),
            );
          },
          backgroundColor: primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    
    return Padding(
      padding: const EdgeInsets.only(right: UIConstants.spacingS),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
          _filterTasks();
        },
        selectedColor: primaryColor.withOpacity(0.2),
        checkmarkColor: primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? primaryColor : textSecondaryColor,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const CenterLoading(
      message: 'Loading tasks...',
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

  Widget _buildEmptyState() {
    final hasSearchQuery = _searchController.text.isNotEmpty;
    final hasCategoryFilter = _selectedCategory != 'All';
    
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
                hasSearchQuery || hasCategoryFilter ? Icons.search_off : Icons.task_alt,
                size: 60,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: UIConstants.spacingL),
            Text(
              hasSearchQuery || hasCategoryFilter 
                  ? 'No tasks found'
                  : 'No tasks available',
              style: TextStyles.heading2.copyWith(color: textPrimaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.spacingM),
            Text(
              hasSearchQuery || hasCategoryFilter
                  ? 'Try adjusting your search or filters to find more tasks'
                  : 'Be the first to post a task and help others in your community!',
              style: TextStyles.body2.copyWith(color: textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.spacingL),
            if (hasSearchQuery || hasCategoryFilter) ...[
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedCategory = 'All';
                  });
                  _filterTasks();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
                style: WidgetStyles.secondaryButtonStyle,
              ),
              const SizedBox(height: UIConstants.spacingM),
            ],
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

  Widget _buildTaskList(List<TaskModel> tasks) {
    return ListView.builder(
      padding: const EdgeInsets.all(UIConstants.spacingM),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return FutureBuilder<String>(
          future: _getUserDisplayName(task.posterId),
          builder: (context, snapshot) {
            final posterName = snapshot.hasData ? snapshot.data! : 'User';
            return TaskCard(
              title: task.title,
              description: task.description,
              location: task.location,
              reward: task.reward,
              postedBy: posterName,
              postedTime: _formatTimeAgo(task.createdAt),
              category: task.category,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TaskDetailsScreen(task: task),
                  ),
                );
              },
              onViewDetails: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TaskDetailsScreen(task: task),
                  ),
                );
              },
            );
          },
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
} 