import 'package:flutter/material.dart';
import '../../../constants/ui_constants.dart';
import '../../../constants/myColors.dart';

class UserAvatar extends StatelessWidget {
  final double size;
  final String? imageUrl;
  final String userName;
  final bool showOnlineStatus;
  final bool isOnline;
  final double? rating;

  const UserAvatar({
    super.key,
    this.size = UIConstants.iconSizeL,
    this.imageUrl,
    required this.userName,
    this.showOnlineStatus = false,
    this.isOnline = false,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Avatar circle
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: imageUrl != null ? null : profileImagePlaceholderColor,
            border: Border.all(
              color: profileImageBorderColor,
              width: 1,
            ),
          ),
          child: imageUrl != null
              ? ClipOval(
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildInitialsAvatar();
                    },
                  ),
                )
              : _buildInitialsAvatar(),
        ),

        // Online status indicator
        if (showOnlineStatus)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: isOnline ? successColor : textSecondaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),

        // Rating badge
        if (rating != null)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: UIConstants.spacingS,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(UIConstants.borderRadiusS),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    size: UIConstants.iconSizeS,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    rating!.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: UIConstants.fontSizeXS,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitialsAvatar() {
    // Get initials from user name
    final initials = _getInitials(userName);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryColor.withOpacity(0.1),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: primaryColor,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return '?';
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    return '${nameParts[0].substring(0, 1)}${nameParts[1].substring(0, 1)}'.toUpperCase();
  }
} 