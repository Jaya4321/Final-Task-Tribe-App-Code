import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../model/authentication_models/user_model.dart';
import '../../../controller/providers/authentication_providers/auth_provider.dart';
import '../../../controller/providers/chat_providers/chat_provider.dart';
import '../../components/shared_components/user_avatar.dart';
import '../../../constants/ui_constants.dart';
import '../../../constants/myColors.dart';
import '../chat_screens/chat_room_screen.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<AuthProvider>(context, listen: false).userData;
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found'));
          }
          final user = UserModel.fromFirestore(snapshot.data!);
          final isOwnProfile = currentUser != null && currentUser.uid == user.uid;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(UIConstants.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Center(
                  child: UserAvatar(
                    size: UIConstants.iconSizeXL * 2,
                    userName: user.displayName ?? 'User',
                    imageUrl: user.photoURL,
                  ),
                ),
                const SizedBox(height: UIConstants.spacingL),
                // Name
                Text(
                  user.displayName ?? 'User',
                  style: TextStyles.heading2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: UIConstants.spacingS),
                // Member since
                Text(
                  'Member since ${_formatMonthYear(user.createdAt)}',
                  style: TextStyles.caption,
                ),
                const SizedBox(height: UIConstants.spacingL),
                // Ratings
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRatingBadge('Poster', user.ratings['asPoster'] ?? 0, user.numberofReviewsAsPoster),
                    const SizedBox(width: UIConstants.spacingL),
                    _buildRatingBadge('Doer', user.ratings['asDoer'] ?? 0, user.numberofReviewsAsDoer),
                  ],
                ),
                const SizedBox(height: UIConstants.spacingL),
                // Bio
                if (user.bio != null && user.bio!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bio', style: TextStyles.heading3),
                      const SizedBox(height: UIConstants.spacingS),
                      Text(user.bio!, style: TextStyles.body2),
                      const SizedBox(height: UIConstants.spacingL),
                    ],
                  ),
                // Task stats
                _buildTaskStats(user.uid),
                const SizedBox(height: UIConstants.spacingL),
                // Contact button
                if (!isOwnProfile)
                  SizedBox(
                    width: double.infinity,
                    height: UIConstants.buttonHeightL,
                    child: OutlinedButton(
                      onPressed: () async {
                        await _handleContactUser(context, user);
                      },
                      style: WidgetStyles.secondaryButtonStyle,
                      child: const Text('Contact'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingBadge(String label, double rating, int reviews) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.star, color: accentColor, size: UIConstants.iconSizeM),
            const SizedBox(width: 4),
            Text(rating.toStringAsFixed(1), style: TextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        Text('$label (${reviews} reviews)', style: TextStyles.caption),
      ],
    );
  }

  Widget _buildStatBadge(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: primaryColor, size: UIConstants.iconSizeM),
        const SizedBox(height: 4),
        Text(count.toString(), style: TextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyles.caption),
      ],
    );
  }

  Widget _buildTaskStats(String userId) {
    return FutureBuilder<Map<String, int>>(
      future: _getTaskStats(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatBadge('Tasks Posted', 0, Icons.post_add),
              const SizedBox(width: UIConstants.spacingL),
              _buildStatBadge('Tasks Accepted', 0, Icons.assignment_turned_in),
            ],
          );
        }

        final stats = snapshot.data ?? {'posted': 0, 'accepted': 0};
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatBadge('Tasks Posted', stats['posted'] ?? 0, Icons.post_add),
            const SizedBox(width: UIConstants.spacingL),
            _buildStatBadge('Tasks Accepted', stats['accepted'] ?? 0, Icons.assignment_turned_in),
          ],
        );
      },
    );
  }

  Future<Map<String, int>> _getTaskStats(String userId) async {
    try {
      // Get tasks posted by this user
      final postedQuery = await FirebaseFirestore.instance
          .collection('tasks')
          .where('posterId', isEqualTo: userId)
          .get();

      // Get tasks accepted by this user (where doerId matches)
      final acceptedQuery = await FirebaseFirestore.instance
          .collection('tasks')
          .where('doerId', isEqualTo: userId)
          .get();

      return {
        'posted': postedQuery.docs.length,
        'accepted': acceptedQuery.docs.length,
      };
    } catch (e) {
      print('Error fetching task stats: $e');
      return {'posted': 0, 'accepted': 0};
    }
  }

  String _formatMonthYear(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _handleContactUser(BuildContext context, UserModel otherUser) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to contact users'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Set current user ID in chat provider
      chatProvider.setCurrentUserId(currentUser.uid);

      // Check if users are blocked
      if (chatProvider.areUsersBlocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot contact this user due to blocking'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Create or get conversation
      final conversationId = await chatProvider.handleContactPoster(
        currentUser.uid,
        otherUser.uid,
      );

      // Hide loading indicator
      Navigator.of(context).pop();

      if (conversationId != null) {
        // Navigate to chat room
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(
              chatId: conversationId,
              userName: otherUser.displayName ?? 'User',
              taskTitle: 'Chat with ${otherUser.displayName ?? 'User'}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start conversation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 