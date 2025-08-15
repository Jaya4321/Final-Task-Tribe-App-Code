import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../constants/chat_constants.dart';
import '../../../constants/ui_constants.dart';
import '../../../constants/myColors.dart';
import '../../../controller/providers/chat_providers/chat_provider.dart';
import '../../../controller/providers/authentication_providers/auth_provider.dart';
import '../../components/shared_components/user_avatar.dart';
import '../../components/shared_components/loading_components.dart';
import 'chat_room_screen.dart';
import '../../../services/firestore_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Set<String> _selectedConversationIds = {};
  bool get _isSelecting => _selectedConversationIds.isNotEmpty;

  // Add a user cache to avoid repeated Firestore lookups
  final Map<String, Map<String, String?>> _userCache = {}; // userId -> {displayName, photoURL}

  // Prevent multiple navigations
  bool _isOpeningChat = false;
  bool _hasVisitedChatRoom = false;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force refresh user names when screen is visited
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      if (currentUser != null && chatProvider.conversations.isNotEmpty) {
        // Ensure current user ID is set
        chatProvider.setCurrentUserId(currentUser.uid);
        chatProvider.refreshUserNamesCache(currentUser.uid);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onConversationLongPress(String conversationId) {
    setState(() {
      if (_selectedConversationIds.contains(conversationId)) {
        _selectedConversationIds.remove(conversationId);
      } else {
        _selectedConversationIds.add(conversationId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedConversationIds.clear();
    });
  }

  Future<void> _deleteSelectedConversations(ChatProvider chatProvider) async {
    if (_selectedConversationIds.isEmpty) return;
    final confirmed = await _showDeleteConversationsConfirmation(context, _selectedConversationIds.length);
    if (confirmed) {
      for (final id in _selectedConversationIds) {
        await chatProvider.deleteConversation(id);
      }
      _clearSelection();
    }
  }

  Future<bool> _showDeleteConversationsConfirmation(BuildContext context, int count) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete Conversation${count > 1 ? 's' : ''}'),
            content: Text('Are you sure you want to delete $count conversation${count > 1 ? 's' : ''}? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ?? false;
  }

  Future<void> _loadChats() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      if (currentUser != null) {
        // Ensure current user ID is set before loading conversations
        chatProvider.setCurrentUserId(currentUser.uid);
        await chatProvider.handleUserLogin(currentUser.uid);
      }
    } catch (e) {
      print('DEBUG: Error in _loadChats: $e');
      // Don't show error to user for temporary issues
    }
  }

  void _filterChats() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final searchQuery = _searchController.text.trim();
    chatProvider.setSearchQuery(searchQuery.isEmpty ? null : searchQuery);
  }

  Widget _buildChatList(List conversations, ChatProvider chatProvider) {
    if (chatProvider.isLoading) {
      return _buildLoadingState();
    }
    
    // For temporary errors, show loading state instead of error
    if (chatProvider.errorMessage != null && 
        (chatProvider.errorMessage!.contains('Concurrent modification') || 
         chatProvider.errorMessage!.contains('Failed to refresh user names'))) {
      return _buildLoadingState();
    }
    
    if (chatProvider.errorMessage != null) {
      return _buildErrorState(chatProvider.errorMessage!);
    }
    if (conversations.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: _loadChats,
      child: ListView.builder(
        padding: const EdgeInsets.all(UIConstants.spacingM),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          final isSelected = _selectedConversationIds.contains(conversation.id);
          return GestureDetector(
            onLongPress: () => _onConversationLongPress(conversation.id),
            onTap: _isSelecting
                ? () => _onConversationLongPress(conversation.id)
                : null,
            child: Stack(
              children: [
                Opacity(
                  opacity: isSelected ? 0.5 : 1.0,
                  child: _buildChatItem(conversation, chatProvider),
                ),
                if (isSelected)
                  Positioned.fill(
                    child: Container(
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(UIConstants.spacingM),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: UIConstants.spacingM),
          padding: const EdgeInsets.all(UIConstants.spacingM),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
          ),
          child: Row(
            children: [
              // Avatar skeleton
              Container(
                width: ChatUIConstants.avatarSize,
                height: ChatUIConstants.avatarSize,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: UIConstants.spacingM),
              // Content skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(UIConstants.borderRadiusS),
                      ),
                    ),
                    const SizedBox(height: UIConstants.spacingS),
                    Container(
                      height: 14,
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(UIConstants.borderRadiusS),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String errorMessage) {
    // For temporary errors, just show empty state instead of error
    if (errorMessage.contains('Concurrent modification') || 
        errorMessage.contains('Failed to refresh user names')) {
      return _buildEmptyState();
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: UIConstants.iconSizeXL,
              color: errorColor,
            ),
            const SizedBox(height: UIConstants.spacingM),
            Text(
              'Failed to load conversations',
              style: TextStyles.heading3.copyWith(color: textPrimaryColor),
            ),
            const SizedBox(height: UIConstants.spacingS),
            Text(
              errorMessage,
              style: TextStyles.body2.copyWith(color: textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: UIConstants.spacingL),
            ElevatedButton(
              onPressed: _loadChats,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: UIConstants.iconSizeXL,
            color: textSecondaryColor,
          ),
          const SizedBox(height: UIConstants.spacingM),
          Text(
            ChatEmptyStateMessages.noConversationsTitle,
            style: TextStyles.heading3.copyWith(color: textSecondaryColor),
          ),
          const SizedBox(height: UIConstants.spacingS),
          Padding(
            padding: const EdgeInsets.only(left: UIConstants.spacingM, right: UIConstants.spacingM),
            child: Text(
              ChatEmptyStateMessages.noConversationsSubtitle,
              style: TextStyles.body2.copyWith(color: textSecondaryColor),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(dynamic conversation, ChatProvider chatProvider) {
    final currentUserId = chatProvider.getCurrentUserId();
    final otherUserId = conversation.getOtherParticipant(currentUserId);
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final hasUnread = conversation.hasUnreadMessages(currentUserId);
    final displayName = chatProvider.getOtherUserName(conversation.id);
    // Note: For avatar, you can extend the cache logic to include photoURL if needed
    return Container(
      margin: const EdgeInsets.only(bottom: UIConstants.spacingS),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(UIConstants.spacingM),
        leading: Stack(
          children: [
            UserAvatar(
              size: ChatUIConstants.avatarSize,
              userName: displayName,
              // imageUrl: photoURL, // Optionally add avatar caching
              showOnlineStatus: true,
              isOnline: true, // This would come from actual data
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UIConstants.spacingS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: errorColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          displayName,
          style: TextStyles.body1.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: ChatUIConstants.userNameFontSize,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: UIConstants.spacingS),
            Text(
              conversation.lastMessage.isNotEmpty 
                  ? conversation.lastMessage 
                  : 'No messages yet',
              style: TextStyles.body2.copyWith(
                color: textSecondaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTimeAgo(conversation.lastMessageTimestamp),
              style: TextStyles.caption,
            ),
          ],
        ),
        onTap: () async {
          if (_isSelecting) {
            _onConversationLongPress(conversation.id);
            return;
          }
          if (_isOpeningChat) return; // Prevent multiple navigations
          setState(() {
            _isOpeningChat = true;
          });
          // Show loading dialog with SpinKit
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: SpinKitSpinningLines(
                color: primaryColor,
                size: 50.0,
                lineWidth: 3.0,
              ),
            ),
          );
          try {
            // Mark conversation as seen
            await chatProvider.markConversationAsSeen(conversation.id, currentUserId);
            Navigator.of(context).pop(); // Dismiss loading dialog
            _hasVisitedChatRoom = true;
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatRoomScreen(
                  chatId: conversation.id,
                  userName: displayName,
                  taskTitle: '',
                ),
              ),
            );
            
            // Refresh user names when returning from chat room
            if (_hasVisitedChatRoom) {
              final chatProvider = Provider.of<ChatProvider>(context, listen: false);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final currentUser = authProvider.currentUser;
              if (currentUser != null) {
                chatProvider.refreshUserNamesOnReturn(currentUser.uid);
              }
            }
          } finally {
            if (mounted) {
              setState(() {
                _isOpeningChat = false;
              });
            }
          }
        },
      ),
    );
  }

  // Helper to fetch user info and cache it
  Future<Map<String, String?>> _getUserInfo(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }
    final doc = await FirestoreService().getUser(userId);
    final info = {
      'displayName': doc?.displayName ?? 'User',
      'photoURL': doc?.photoURL,
    };
    _userCache[userId] = info;
    return info;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return Scaffold(
          backgroundColor: scaffoldBackgroundColor,
          appBar: AppBar(
            centerTitle: true,
            title: _isSelecting
                ? Text('${_selectedConversationIds.length} selected')
                : const Text('Chats'),
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              if (_isSelecting)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteSelectedConversations(chatProvider),
                ),
              
            ],
            leading: _isSelecting
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearSelection,
                  )
                : null,
          ),
          body: Column(
            children: [
              // Search bar
              Container(
                padding: const EdgeInsets.all(UIConstants.spacingM),
                color: Colors.white,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterChats();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(UIConstants.borderRadiusM),
                    ),
                  ),
                  onChanged: (value) => _filterChats(),
                ),
              ),

              // Chat list
              Expanded(
                child: _buildChatList(chatProvider.filteredConversations, chatProvider),
              ),
            ],
          ),
        );
      },
    );
  }
} 