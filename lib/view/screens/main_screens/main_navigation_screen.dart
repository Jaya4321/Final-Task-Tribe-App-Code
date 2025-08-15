import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/ui_constants.dart';
import '../../../constants/myColors.dart';
import '../task_screens/task_feed_screen.dart';
import '../task_screens/my_tasks_screen.dart';
import '../chat_screens/chat_list_screen.dart';
import '../profile_screens/profile_screen.dart';
import '../../../controller/providers/chat_providers/chat_provider.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TaskFeedScreen(),
    const MyTasksScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 4.0,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: UIConstants.spacingM,
              vertical: UIConstants.spacingS,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.work,
                  label: 'Tasks',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.assignment,
                  label: 'My Tasks',
                ),
                Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    final unreadCount = chatProvider.totalUnreadMessagesCount;
                    return _buildNavItem(
                      index: 2,
                      icon: Icons.chat,
                      label: 'Chats',
                      badge: unreadCount > 0 ? unreadCount.toString() : null,
                    );
                  },
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.person,
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    String? badge,
  }) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: UIConstants.spacingM,
          vertical: UIConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  size: UIConstants.iconSizeM,
                  color: isSelected ? primaryColor : textSecondaryColor,
                ),
                // Red dot indicator for unread messages (only for chat tab)
                if (index == 2)
                  Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) {
                      final unreadCount = chatProvider.totalUnreadMessagesCount;
                      if (unreadCount > 0) {
                        return Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
            const SizedBox(height: UIConstants.spacingS),
            Text(
              label,
              style: TextStyle(
                fontSize: UIConstants.fontSizeS,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected ? primaryColor : textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 