import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../controller/providers/task_providers/task_provider.dart';
import '../../../controller/providers/authentication_providers/auth_provider.dart';
import '../../../model/task_models/task_model.dart';
import '../../../model/authentication_models/user_model.dart';
import '../../../constants/myColors.dart';
import '../../../services/notification_helper.dart';
import '../../components/shared_components/task_card.dart';

class MutualTaskProposalScreen extends StatefulWidget {
  final TaskModel targetTask;

  const MutualTaskProposalScreen({
    Key? key,
    required this.targetTask,
  }) : super(key: key);

  @override
  State<MutualTaskProposalScreen> createState() => _MutualTaskProposalScreenState();
}

class _MutualTaskProposalScreenState extends State<MutualTaskProposalScreen> {
  TaskModel? selectedTask;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserMutualTasks();
    });
  }

  Future<void> _loadUserMutualTasks() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      await taskProvider.loadUserMutualTasks(
        authProvider.currentUser!.uid,
        status: TaskStatus.open,
      );
    }
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

  Future<void> _proposeMutualTask() async {
    if (selectedTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a task to offer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      final success = await taskProvider.proposeMutualTask(
        widget.targetTask.id,
        selectedTask!.id,
        authProvider.currentUser!.uid,
      );

      if (success) {
        // Send notification to task poster about the proposal
        await NotificationHelper.notifyMutualTaskProposalReceived(
          taskOwnerId: widget.targetTask.posterId,
          taskTitle: widget.targetTask.title,
          proposerId: authProvider.currentUser!.uid,
          taskId: widget.targetTask.id,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mutual task proposal sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send proposal. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Propose Mutual Task'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<AuthProvider, TaskProvider>(
        builder: (context, authProvider, taskProvider, child) {
          if (taskProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }

          final userMutualTasks = taskProvider.mutualTasks
              .where((task) => 
                  task.isOpen && 
                  task.posterId == authProvider.currentUser?.uid &&
                  widget.targetTask.canProposeWithTask(authProvider.currentUser!.uid, task.id))
              .toList();

          if (userMutualTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Available Tasks for Proposal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You either have no mutual tasks or all your tasks have been rejected for this exchange. Create a new mutual task to propose.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Target task section
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Task',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<String>(
                      future: _getUserDisplayName(widget.targetTask.posterId),
                      builder: (context, snapshot) {
                        final posterName = snapshot.hasData ? snapshot.data! : 'User';
                        return TaskCard(
                          title: widget.targetTask.title,
                          description: widget.targetTask.description,
                          location: widget.targetTask.location,
                          reward: widget.targetTask.reward,
                          postedBy: posterName,
                          postedTime: '${widget.targetTask.createdAt.day}/${widget.targetTask.createdAt.month}/${widget.targetTask.createdAt.year}',
                          status: widget.targetTask.status,
                          category: widget.targetTask.category,
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Your mutual tasks section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Select Your Task to Offer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: userMutualTasks.length,
                        itemBuilder: (context, index) {
                          final task = userMutualTasks[index];
                          final isSelected = selectedTask?.id == task.id;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isSelected ? primaryColor.withOpacity(0.1) : null,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  selectedTask = isSelected ? null : task;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Radio<TaskModel>(
                                      value: task,
                                      groupValue: selectedTask,
                                      onChanged: (TaskModel? value) {
                                        setState(() {
                                          selectedTask = value;
                                        });
                                      },
                                      activeColor: primaryColor,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            task.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 16,
                                                color: Colors.grey[500],
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  task.location,
                                                  style: TextStyle(
                                                    color: Colors.grey[500],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // Submit button
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedTask != null && !isSubmitting
                        ? _proposeMutualTask
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Propose Exchange',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 