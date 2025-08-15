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
import '../../components/shared_components/user_avatar.dart';
import '../../../services/task_service.dart';

class MutualTaskManagementScreen extends StatefulWidget {
  final TaskModel task;
  const MutualTaskManagementScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<MutualTaskManagementScreen> createState() => _MutualTaskManagementScreenState();
}

class _MutualTaskManagementScreenState extends State<MutualTaskManagementScreen> {
  String? _loadingProposalId;
  TaskModel? _currentTask;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    // Try to get the latest version from provider
    final updated = taskProvider.userTasks.firstWhere(
      (t) => t.id == widget.task.id,
      orElse: () => widget.task,
    );
    setState(() {
      _currentTask = updated;
    });
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

  Future<void> _acceptProposal(String proposerUserId) async {
    setState(() {
      _loadingProposalId = proposerUserId;
    });
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final success = await taskProvider.acceptMutualProposal(widget.task.id, proposerUserId);
    if (success) {
      // Send notification to the accepted proposer
      await NotificationHelper.notifyMutualTaskProposalAccepted(
        proposerId: proposerUserId,
        taskTitle: widget.task.title,
        taskId: widget.task.id,
      );

      // Send notifications to all other pending proposers that they were not accepted
      final pendingProposals = widget.task.mutualProposals
          .where((p) => p.status == MutualStatus.pending && p.proposerUserId != proposerUserId)
          .map((p) => p.proposerUserId)
          .toList();

      if (pendingProposals.isNotEmpty) {
        // Send rejection notifications to all other pending proposers
        for (final rejectedProposerId in pendingProposals) {
          await NotificationHelper.notifyMutualTaskProposalRejected(
            proposerId: rejectedProposerId,
            taskTitle: widget.task.title,
            taskId: widget.task.id,
          );
        }
      }

      await _loadTask();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proposal accepted successfully!'), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to accept proposal. Please try again.'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() {
      _loadingProposalId = null;
    });
  }

  Future<void> _rejectProposal(String proposerUserId) async {
    setState(() {
      _loadingProposalId = proposerUserId;
    });
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final success = await taskProvider.rejectMutualProposal(widget.task.id, proposerUserId);
    if (success) {
      // Send notification to the rejected proposer
      await NotificationHelper.notifyMutualTaskProposalRejected(
        proposerId: proposerUserId,
        taskTitle: widget.task.title,
        taskId: widget.task.id,
      );

      await _loadTask();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proposal rejected successfully!'), backgroundColor: Colors.orange),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to reject proposal. Please try again.'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() {
      _loadingProposalId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final task = _currentTask ?? widget.task;
    final proposals = task.mutualProposals;
    final hasAccepted = task.getAcceptedMutualProposal() != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mutual Task Proposals'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: proposals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No Proposals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('No one has proposed a mutual exchange for this task yet.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadTask,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Task info
                  Row(
                    children: [
                      Expanded(
                        child: Text('Your Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                      ),
                      if (hasAccepted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(12)),
                          child: Text('Accepted', style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TaskCard(
                    title: task.title,
                    description: task.description,
                    location: task.location,
                    reward: task.reward,
                    postedBy: 'You',
                    postedTime: '${task.createdAt.day}/${task.createdAt.month}/${task.createdAt.year}',
                    status: task.status,
                    category: task.category,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    hasAccepted ? 'Proposals (1 Accepted)' : 'Proposals (${proposals.where((p) => p.status == MutualStatus.pending).length} Pending)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  ...proposals.map((proposal) => _buildProposalCard(task, proposal)).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildProposalCard(TaskModel task, MutualProposal proposal) {
    final hasAcceptedProposal = task.getAcceptedMutualProposal() != null;
    final isThisProposalAccepted = proposal.status == MutualStatus.accepted;
    final isThisProposalRejected = proposal.status == MutualStatus.rejected;
    final shouldShowButtons = !hasAcceptedProposal && proposal.status == MutualStatus.pending;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String>(
              future: _getUserDisplayName(proposal.proposerUserId),
              builder: (context, snapshot) {
                final proposerName = snapshot.hasData ? snapshot.data! : 'User';
                return Row(
                  children: [
                    UserAvatar(size: 40, userName: proposerName),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(proposerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            isThisProposalAccepted ? 'Proposal accepted' : isThisProposalRejected ? 'Proposal rejected' : 'Wants to exchange tasks',
                            style: TextStyle(
                              color: isThisProposalAccepted ? Colors.green[600] : isThisProposalRejected ? Colors.red[600] : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isThisProposalAccepted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(12)),
                        child: Text('Accepted', style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    else if (isThisProposalRejected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(12)),
                        child: Text('Rejected', style: TextStyle(color: Colors.red[700], fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Text('Proposed Exchange', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const SizedBox(height: 8),
            FutureBuilder<TaskModel?>(
              future: () async {
                final tasks = Provider.of<TaskProvider>(context, listen: false).tasks;
                try {
                  return tasks.firstWhere((t) => t.id == proposal.offeredTaskId);
                } catch (e) {
                  await Provider.of<TaskProvider>(context, listen: false).loadTasks();
                  final refreshed = Provider.of<TaskProvider>(context, listen: false).tasks;
                  try {
                    return refreshed.firstWhere((t) => t.id == proposal.offeredTaskId);
                  } catch (e) {
                    return null;
                  }
                }
              }(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
                }
                final proposedTask = snapshot.data;
                if (proposedTask != null) {
                  return FutureBuilder<String>(
                    future: _getUserDisplayName(proposal.proposerUserId),
                    builder: (context, nameSnapshot) {
                      final proposerName = nameSnapshot.hasData ? nameSnapshot.data! : 'User';
                      return Column(
                        children: [
                          TaskCard(
                            title: proposedTask.title,
                            description: proposedTask.description,
                            location: proposedTask.location,
                            reward: proposedTask.reward,
                            postedBy: proposerName,
                            postedTime: '${proposedTask.createdAt.day}/${proposedTask.createdAt.month}/${proposedTask.createdAt.year}',
                            status: proposedTask.status,
                            category: proposedTask.category,
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  );
                }
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                  child: Text('Proposed task details not available', style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
                );
              },
            ),
            const SizedBox(height: 12),
            if (shouldShowButtons) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loadingProposalId == proposal.proposerUserId ? null : () => _acceptProposal(proposal.proposerUserId),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: _loadingProposalId == proposal.proposerUserId
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loadingProposalId == proposal.proposerUserId ? null : () => _rejectProposal(proposal.proposerUserId),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: _loadingProposalId == proposal.proposerUserId
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ] else if (hasAcceptedProposal && !isThisProposalAccepted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Another proposal was accepted for this task', style: TextStyle(color: Colors.orange[700], fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 