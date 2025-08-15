import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../controller/providers/authentication_providers/auth_provider.dart';
import '../../../controller/providers/authentication_providers/profile_provider.dart';
import '../../components/shared_components/loading_components.dart';
import '../../../constants/auth_constants.dart';
import '../../../constants/myColors.dart';
import '../../../utils/auth_helpers.dart';
import '../authentication_screens/change_password_screen.dart';
import '../authentication_screens/login_screen.dart';
import 'update_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late AuthProvider _authProvider;
  late ProfileProvider _profileProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    
    // Debug: Print current auth state
    print('DEBUG: ProfileScreen initState - isAuthenticated: ${_authProvider.isAuthenticated}, isLoading: ${_authProvider.isLoading}, userData: ${_authProvider.userData?.uid}');
    
    // Debug: Print user data details if available
    if (_authProvider.userData != null) {
      print('DEBUG: ProfileScreen - User data details:');
      print('DEBUG: - numberofReviewsAsPoster: ${_authProvider.userData!.numberofReviewsAsPoster}');
      print('DEBUG: - numberofReviewsAsDoer: ${_authProvider.userData!.numberofReviewsAsDoer}');
      print('DEBUG: - ratings: ${_authProvider.userData!.ratings}');
    }
  }

  void _editProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const UpdateProfileScreen(),
      ),
    );
  }

  void _changePassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
  }

  Future<void> _signOut() async {
    final confirmed = await AuthHelpers.showConfirmationDialog(
      context: context,
      title: AuthConstants.signOutTitle,
      message: AuthConstants.signOutMessage,
      confirmText: AuthConstants.signOut,
      cancelText: AuthConstants.cancel,
    );

    if (confirmed) {
      _profileProvider.clearSelectedImage();
      final result = await _authProvider.signOut();
      if (result.success && mounted) {
        // Navigate to login screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await AuthHelpers.showConfirmationDialog(
      context: context,
      title: AuthConstants.deleteAccountTitle,
      message: AuthConstants.deleteAccountMessage,
      confirmText: AuthConstants.delete,
      cancelText: AuthConstants.cancel,
      isDestructive: true,
    );

    if (confirmed) {
      // Show password input dialog for account deletion
      final password = await _showPasswordDialog();
      if (password != null) {
        final result = await _authProvider.deleteAccount(password);
        if (result.success && mounted) {
          // Navigate to login screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
          );
        }
      }
    }
  }

  Future<String?> _showPasswordDialog() async {
    final passwordController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AuthConstants.confirmPasswordTitle,
              style: TextStyle(color: textPrimaryColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AuthConstants.confirmPasswordMessage,
                  style: TextStyle(color: textSecondaryColor)),
              const SizedBox(height: AuthConstants.defaultPadding),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: inputLabelColor),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: inputFocusedBorderColor),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: textSecondaryColor),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(passwordController.text),
              style: TextButton.styleFrom(foregroundColor: errorColor),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _selectProfileImage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AuthConstants.selectImageSourceTitle,
              style: TextStyle(color: textPrimaryColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: iconSecondaryColor),
                title: Text(AuthConstants.galleryOption,
                    style: TextStyle(color: textPrimaryColor)),
                onTap: () {
                  Navigator.of(context).pop();
                  _profileProvider.selectImageFromGallery();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: iconSecondaryColor),
                title: Text(AuthConstants.cameraOption,
                    style: TextStyle(color: textPrimaryColor)),
                onTap: () {
                  Navigator.of(context).pop();
                  _profileProvider.selectImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _authProvider.isLoading || _profileProvider.isUploading,
      message:
          _authProvider.isLoading ? 'Loading profile...' : AuthConstants.uploadingImage,
      child: Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Profile', style: TextStyle(color: textPrimaryColor)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: iconPrimaryColor),
        ),
        body: SafeArea(
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.userData;
              
              // Debug: Print user data in build method
              if (user != null) {
                print('DEBUG: ProfileScreen build - User data:');
                print('DEBUG: - numberofReviewsAsPoster: ${user.numberofReviewsAsPoster}');
                print('DEBUG: - numberofReviewsAsDoer: ${user.numberofReviewsAsDoer}');
                print('DEBUG: - ratings: ${user.ratings}');
              }
              
              // Show loading if user data is not loaded
              if (authProvider.isLoading && user == null) {
                return const CenterLoading(
                  message: 'Loading profile...',
                  size: 50.0,
                );
              }
              
              // Show error if user is not authenticated
              if (!authProvider.isAuthenticated || user == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: errorColor),
                      const SizedBox(height: 16),
                      Text(
                        'Profile not available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please log in to view your profile',
                        style: TextStyle(
                          color: textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image
                    Center(
                      child: GestureDetector(
                        onTap: _selectProfileImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: profileImageBorderColor,
                              width: 3,
                            ),
                          ),
                          child: ClipOval(
                            child: Consumer<ProfileProvider>(
                              builder: (context, profileProvider, child) {
                                if (profileProvider.selectedImage != null) {
                                  return Image.file(
                                    profileProvider.selectedImage!,
                                    fit: BoxFit.cover,
                                  );
                                } else if (user.photoURL != null &&
                                    user.photoURL!.isNotEmpty) {
                                  return Image.network(
                                    user.photoURL!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: profileImagePlaceholderColor,
                                        child: Icon(
                                          Icons.person,
                                          size: 50,
                                          color: primaryColor,
                                        ),
                                      );
                                    },
                                  );
                                } else {
                                  return Container(
                                    color: profileImagePlaceholderColor,
                                    child: Icon(
                                      Icons.person,
                                      size: 50,
                                      color: primaryColor,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    Text(
                      user.displayName ?? 'No Name',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // User Information Card
                    Card(
                      color: cardColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Email
                            _buildInfoRow(
                              icon: Icons.email,
                              label: 'Email',
                              value: user.email,
                              isReadOnly: true,
                            ),

                            // Phone Number
                            if (user.phoneNumber != null &&
                                user.phoneNumber!.isNotEmpty)
                              _buildInfoRow(
                                icon: Icons.phone,
                                label: 'Phone',
                                value: user.phoneNumber!,
                                isReadOnly: true,
                              ),

                            // Bio
                            if (user.bio != null && user.bio!.isNotEmpty)
                              _buildInfoRow(
                                icon: Icons.person_outline,
                                label: 'Bio',
                                value: user.bio!,
                                isReadOnly: true,
                                isMultiLine: true,
                              ),

                            const SizedBox(height: 16),

                            // Ratings Section
                            Text(
                              'Ratings',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildRatingCard(
                                    title: 'As Poster',
                                    rating: user.ratings['asPoster'] ?? 0.0,
                                    icon: Icons.post_add,
                                    reviews: user.numberofReviewsAsPoster,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildRatingCard(
                                    title: 'As Doer',
                                    rating: user.ratings['asDoer'] ?? 0.0,
                                    icon: Icons.work,
                                    reviews: user.numberofReviewsAsDoer,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Task Statistics
                            Text(
                              'Task Statistics',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),

                            _buildTaskStats(user.uid),

                            const SizedBox(height: 8),

                            // Member Since
                            _buildInfoRow(
                              icon: Icons.calendar_today,
                              label: 'Member Since',
                              value: _formatDate(user.createdAt),
                              isReadOnly: true,
                            ),

                            // Last Login
                            _buildInfoRow(
                              icon: Icons.access_time,
                              label: 'Last Login',
                              value: _formatDate(user.lastLoginAt),
                              isReadOnly: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    // Action Buttons as ListTiles
                    Card(
                      color: cardColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.edit, color: primaryColor),
                            title: Text('Edit Profile',
                                style: TextStyle(
                                    color: textPrimaryColor,
                                    fontWeight: FontWeight.w500)),
                            trailing: Icon(Icons.arrow_forward_ios,
                                color: iconSecondaryColor, size: 18),
                            onTap: _editProfile,
                          ),
                          Divider(height: 1, color: dividerColor),
                          ListTile(
                            leading: Icon(Icons.lock, color: primaryColor),
                            title: Text('Change Password',
                                style: TextStyle(
                                    color: textPrimaryColor,
                                    fontWeight: FontWeight.w500)),
                            trailing: Icon(Icons.arrow_forward_ios,
                                color: iconSecondaryColor, size: 18),
                            onTap: _changePassword,
                          ),
                          Divider(height: 1, color: dividerColor),
                          ListTile(
                            leading: Icon(Icons.logout, color: primaryColor),
                            title: Text('Sign Out',
                                style: TextStyle(
                                    color: textPrimaryColor,
                                    fontWeight: FontWeight.w500)),
                            trailing: Icon(Icons.arrow_forward_ios,
                                color: iconSecondaryColor, size: 18),
                            onTap: _signOut,
                          ),
                          Divider(height: 1, color: dividerColor),
                          ListTile(
                            leading:
                                Icon(Icons.delete_forever, color: errorColor),
                            title: Text('Delete Account',
                                style: TextStyle(
                                    color: errorColor,
                                    fontWeight: FontWeight.w500)),
                            trailing: Icon(Icons.arrow_forward_ios,
                                color: iconSecondaryColor, size: 18),
                            onTap: _deleteAccount,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isReadOnly = false,
    bool isMultiLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textPrimaryColor,
                ),
              ),
              if (isReadOnly) ...[
                const SizedBox(width: 4),
                Icon(Icons.lock, color: iconSecondaryColor, size: 14),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: isMultiLine ? null : 1,
              overflow: isMultiLine ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard({
    required String title,
    required double rating,
    required IconData icon,
    required int reviews,
  }) {
    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primaryColor, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textPrimaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                if (index < rating.floor()) {
                  return Icon(Icons.star, color: Colors.amber, size: 18);
                } else if (index == rating.floor() && rating % 1 > 0) {
                  return Icon(Icons.star_half, color: Colors.amber, size: 18);
                } else {
                  return Icon(Icons.star_border, color: Colors.grey, size: 18);
                }
              }),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(width: 4),
                Text(
                  '($reviews reviews)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
  }) {
    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primaryColor, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textPrimaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'N/A';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  // Get task statistics from Firestore
  Future<Map<String, int>> _getTaskStats(String userId) async {
    try {
      final tasksCollection = FirebaseFirestore.instance.collection('tasks');
      
      // Get tasks posted by user
      final postedQuery = await tasksCollection
          .where('posterId', isEqualTo: userId)
          .get();
      
      // Get tasks accepted by user
      final acceptedQuery = await tasksCollection
          .where('doerId', isEqualTo: userId)
          .get();
      
      return {
        'posted': postedQuery.docs.length,
        'accepted': acceptedQuery.docs.length,
      };
    } catch (e) {
      print('Error getting task stats: $e');
      return {'posted': 0, 'accepted': 0};
    }
  }

  // Build task statistics widget
  Widget _buildTaskStats(String userId) {
    return FutureBuilder<Map<String, int>>(
      future: _getTaskStats(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Tasks Posted',
                  count: 0,
                  icon: Icons.post_add,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'Tasks Accepted',
                  count: 0,
                  icon: Icons.work,
                ),
              ),
            ],
          );
        }

        final stats = snapshot.data ?? {'posted': 0, 'accepted': 0};
        
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Tasks Posted',
                count: stats['posted'] ?? 0,
                icon: Icons.post_add,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                title: 'Tasks Accepted',
                count: stats['accepted'] ?? 0,
                icon: Icons.work,
              ),
            ),
          ],
        );
      },
    );
  }
}
