import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/chat_constants.dart';
import '../../../constants/ui_constants.dart';
import '../../../constants/myColors.dart';
import '../../../controller/providers/chat_providers/chat_provider.dart';
import '../../../controller/providers/authentication_providers/auth_provider.dart';
import '../../../model/chat_models/chat_message_model.dart';
import '../../components/shared_components/user_avatar.dart';
import '../profile_screens/user_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String userName;
  final String taskTitle;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.userName,
    required this.taskTitle,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Set<String> _selectedMessageIds = {};
  bool get _isSelecting => _selectedMessageIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onMessageLongPress(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMessageIds.clear();
    });
  }

  Future<void> _deleteSelectedMessages(ChatProvider chatProvider) async {
    if (_selectedMessageIds.isEmpty) return;
    final confirmed = await _showDeleteMessagesConfirmation(context, _selectedMessageIds.length);
    if (confirmed) {
      await chatProvider.deleteMessages(widget.chatId, _selectedMessageIds.toList());
      _clearSelection();
    }
  }

  Future<bool> _showDeleteMessagesConfirmation(BuildContext context, int count) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete Message${count > 1 ? 's' : ''}'),
            content: Text('Are you sure you want to delete $count message${count > 1 ? 's' : ''}? This action cannot be undone.'),
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

  Future<void> _loadMessages() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final currentUser = authProvider.currentUser;
    if (currentUser != null) {
      // Ensure current user ID is set
      chatProvider.setCurrentUserId(currentUser.uid);
      
      // Clear any existing messages first to prevent showing old data
      chatProvider.clearCurrentConversation();
      
      // Load conversation messages
      await chatProvider.loadConversationMessages(widget.chatId);
      
      // Load other user data
      await chatProvider.loadOtherUserData(widget.chatId, currentUser.uid);
      
      // Check block status
      final otherUserId = await _getOtherUserId(widget.chatId, currentUser.uid);
      if (otherUserId != null) {
        await chatProvider.checkBlockStatus(currentUser.uid, otherUserId);
      }
      
      // Mark all messages as seen
      await chatProvider.markAllMessagesAsSeen(widget.chatId);
    }

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Helper method to get other user ID from conversation
  Future<String?> _getOtherUserId(String conversationId, String currentUserId) async {
    try {
      final conversation = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .get();
      
      if (conversation.exists) {
        final data = conversation.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        return participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );
      }
      return null;
    } catch (e) {
      print('DEBUG: Error getting other user ID: $e');
      return null;
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final currentUser = authProvider.currentUser;
    if (currentUser == null) return;

    // Check if users are blocked
    if (!chatProvider.canSendMessage()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(BlockUserMessages.cannotSendToBlocked),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    chatProvider.sendMessage(widget.chatId, _messageController.text.trim());
    _messageController.clear();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return Scaffold(
            backgroundColor: scaffoldBackgroundColor,
            appBar: AppBar(
              title: _isSelecting
                  ? Text('${_selectedMessageIds.length} selected')
                  : Text(
                      widget.userName,
                      style: TextStyles.body1.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Icon(_isSelecting ? Icons.close : Icons.arrow_back),
                onPressed: () {
                  if (_isSelecting) {
                    _clearSelection();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
              actions: [
                if (_isSelecting)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteSelectedMessages(chatProvider),
                  ),
                if (!_isSelecting)
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showMoreOptions(chatProvider);
                    },
                  ),
              ],
            ),
            body: Column(
              children: [
                // Block status banner
                if (chatProvider.areUsersBlocked) _buildBlockStatusBanner(chatProvider),
                
                // Messages list
                Expanded(
                  child: chatProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildMessagesList(chatProvider),
                ),
                
                // Input area
                if (!chatProvider.areUsersBlocked) _buildInputArea(chatProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlockStatusBanner(ChatProvider chatProvider) {
    String message;
    Color backgroundColor;
    
    if (chatProvider.isUserBlocked) {
      message = BlockUserMessages.blockedByUser;
      backgroundColor = BlockUserUIConstants.blockBannerColor;
    } else if (chatProvider.hasBlockedUser) {
      message = BlockUserMessages.hasBlockedUser;
      backgroundColor = BlockUserUIConstants.unblockBannerColor;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: BlockUserUIConstants.bannerPadding,
        vertical: UIConstants.spacingS,
      ),
      color: backgroundColor,
      child: Row(
        children: [
          Icon(
            Icons.block,
            size: BlockUserUIConstants.bannerIconSize,
            color: Colors.red,
          ),
          const SizedBox(width: UIConstants.spacingS),
          Expanded(
            child: Text(
              message,
              style: TextStyles.body2.copyWith(
                color: chatProvider.isUserBlocked 
                    ? BlockUserUIConstants.blockTextColor 
                    : BlockUserUIConstants.unblockTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (chatProvider.hasBlockedUser)
            TextButton(
              onPressed: () => _unblockUser(chatProvider),
              child: const Text(
                BlockUserDialogMessages.unblockConfirm,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.spacingM),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: inputBackgroundColor,
                borderRadius: BorderRadius.circular(ChatUIConstants.inputBorderRadius),
                border: Border.all(color: inputBorderColor),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: UIConstants.spacingM,
                    vertical: UIConstants.spacingS,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                enabled: !chatProvider.isSendingMessage,
              ),
            ),
          ),
          const SizedBox(width: UIConstants.spacingS),
          Container(
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ChatProvider chatProvider) {
    final messages = chatProvider.messages;
    if (messages.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(UIConstants.spacingM),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isSelected = _selectedMessageIds.contains(message.id);
        return GestureDetector(
          onLongPress: () => _onMessageLongPress(message.id),
          onTap: _isSelecting
              ? () => _onMessageLongPress(message.id)
              : null,
          child: Stack(
            children: [
              Opacity(
                opacity: isSelected ? 0.5 : 1.0,
                child: _buildMessageBubble(message, chatProvider),
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
            ChatEmptyStateMessages.noMessagesTitle,
            style: TextStyles.heading3.copyWith(color: textSecondaryColor),
          ),
          const SizedBox(height: UIConstants.spacingS),
          Text(
            ChatEmptyStateMessages.noMessagesSubtitle,
            style: TextStyles.body2.copyWith(color: textSecondaryColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, ChatProvider chatProvider) {
    final currentUserId = chatProvider.getCurrentUserId();
    final isSent = message.senderId == currentUserId;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.spacingM),
      child: Row(
        mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            UserAvatar(
              size: UIConstants.iconSizeM,
              userName: widget.userName,
            ),
            const SizedBox(width: UIConstants.spacingS),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: ChatUIConstants.messageMaxWidth,
              ),
              padding: const EdgeInsets.all(ChatUIConstants.messagePadding),
              decoration: BoxDecoration(
                color: isSent 
                    ? ChatUIConstants.sentMessageColor 
                    : ChatUIConstants.receivedMessageColor,
                borderRadius: BorderRadius.circular(ChatUIConstants.bubbleBorderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isSent 
                          ? ChatUIConstants.sentMessageTextColor 
                          : ChatUIConstants.receivedMessageTextColor,
                      fontSize: ChatUIConstants.messageFontSize,
                    ),
                  ),
                  const SizedBox(height: UIConstants.spacingS),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.getFormattedTime(),
                        style: TextStyle(
                          color: isSent 
                              ? ChatUIConstants.sentMessageTextColor.withOpacity(0.7)
                              : textSecondaryColor,
                          fontSize: ChatUIConstants.timestampFontSize,
                        ),
                      ),
                      if (message.edited) ...[
                        const SizedBox(width: UIConstants.spacingS),
                        Text(
                          '(edited)',
                          style: TextStyle(
                            color: isSent 
                                ? ChatUIConstants.sentMessageTextColor.withOpacity(0.7)
                                : textSecondaryColor,
                            fontSize: ChatUIConstants.timestampFontSize,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if (isSent) ...[
                        const SizedBox(width: UIConstants.spacingS),
                        _buildMessageStatus(message.seen),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageStatus(bool seen) {
    IconData icon = seen ? Icons.done_all : Icons.done;
    Color color = seen ? Colors.green : ChatUIConstants.sentMessageTextColor.withOpacity(0.7);
    
    return Icon(
      icon,
      size: UIConstants.iconSizeS,
      color: color,
    );
  }

  void _showMoreOptions(ChatProvider chatProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(UIConstants.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to user profile
                if (chatProvider.otherUser != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        userId: chatProvider.otherUser!.uid,
                      ),
                    ),
                  );
                }
              },
            ),
            if (!chatProvider.hasBlockedUser)
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Block User', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop();
                  _blockUser(chatProvider);
                },
              ),
            if (chatProvider.hasBlockedUser)
              ListTile(
                leading: const Icon(Icons.block, color: Colors.green),
                title: const Text('Unblock User', style: TextStyle(color: Colors.green)),
                onTap: () {
                  Navigator.of(context).pop();
                  _unblockUser(chatProvider);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _blockUser(ChatProvider chatProvider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(BlockUserDialogMessages.blockUserTitle),
        content: const Text(BlockUserDialogMessages.blockUserMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(BlockUserDialogMessages.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(BlockUserDialogMessages.blockConfirm, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      final success = await chatProvider.blockUser(currentUser.uid, chatProvider.otherUser?.uid ?? '');
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(BlockUserMessages.userBlocked),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(BlockUserMessages.failedToBlock),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unblockUser(ChatProvider chatProvider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(BlockUserDialogMessages.unblockUserTitle),
        content: const Text(BlockUserDialogMessages.unblockUserMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(BlockUserDialogMessages.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(BlockUserDialogMessages.unblockConfirm, style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      final success = await chatProvider.unblockUser(currentUser.uid, chatProvider.otherUser?.uid ?? '');
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(BlockUserMessages.userUnblocked),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(BlockUserMessages.failedToUnblock),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 