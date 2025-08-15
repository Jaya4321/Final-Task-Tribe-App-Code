import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controller/providers/authentication_providers/auth_provider.dart';
import '../../../controller/providers/authentication_providers/profile_provider.dart';
import '../../components/authentication_components/auth_button.dart';
import '../../components/authentication_components/auth_text_field.dart';
import '../../components/shared_components/loading_components.dart';
import '../../../constants/auth_constants.dart';
import '../../../constants/myColors.dart';
import '../../../utils/auth_helpers.dart';
import '../../../utils/auth_validators.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  late AuthProvider _authProvider;
  late ProfileProvider _profileProvider;
  
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  Map<String, String?> _errors = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    
    // Initialize with current user data
    final user = _authProvider.userData;
    if (user != null) {
      _displayNameController.text = user.displayName ?? '';
      _phoneNumberController.text = user.phoneNumber ?? '';
      _bioController.text = user.bio ?? '';
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneNumberController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _errors = AuthValidators.validateProfileForm(
        displayName: _displayNameController.text,
        bio: _bioController.text,
        phoneNumber: _phoneNumberController.text,
      );
    });
  }

  Future<void> _selectProfileImage() async {
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

  Future<void> _saveChanges() async {
    _validateForm();
    
    if (!AuthValidators.isFormValid(_errors)) {
      return;
    }

    final user = _authProvider.userData;
    if (user == null) {
      AuthHelpers.showErrorToast('User data not available');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? newPhotoURL;
      final oldPhotoURL = user.photoURL;
      final newDisplayName = _displayNameController.text.trim();

      // Check if display name has changed
      final displayNameChanged = newDisplayName != (user.displayName ?? '');
      
      // Check if phone number has changed
      final phoneNumberChanged = _phoneNumberController.text.trim() != (user.phoneNumber ?? '');
      
      // Check if bio has changed
      final bioChanged = _bioController.text.trim() != (user.bio ?? '');
      
      // Check if image has been selected
      final imageSelected = _profileProvider.hasSelectedImage;

      if (!displayNameChanged && !phoneNumberChanged && !bioChanged && !imageSelected) {
        AuthHelpers.showToast(AuthConstants.noChangesToSave);
        return;
      }

      // Upload new image if selected
      if (imageSelected) {
        print('DEBUG: Starting image upload...');
        newPhotoURL = await _profileProvider.updateUserProfile(
          userId: user.uid,
        );
        
        if (newPhotoURL == null) {
          print('DEBUG: Image upload failed');
          AuthHelpers.showErrorToast(_profileProvider.errorMessage ?? 'Failed to upload image');
          return;
        }
        print('DEBUG: Image uploaded successfully: $newPhotoURL');
      }

      // Update profile
      print('DEBUG: Updating profile with newPhotoURL: $newPhotoURL');
      final result = await _authProvider.updateProfile(
        displayName: displayNameChanged ? newDisplayName : null,
        photoURL: newPhotoURL,
        bio: bioChanged ? _bioController.text.trim() : null,
        phoneNumber: phoneNumberChanged ? _phoneNumberController.text.trim() : null,
      );

      if (result.success) {
        print('DEBUG: Profile update successful');
        // Delete old image only after successful profile update
        if (newPhotoURL != null && 
            oldPhotoURL != null && 
            oldPhotoURL.isNotEmpty && 
            oldPhotoURL != newPhotoURL) {
          print('DEBUG: Deleting old image: $oldPhotoURL');
          await _profileProvider.deleteProfileImage(oldPhotoURL);
        }
        
        AuthHelpers.showSuccessToast(AuthConstants.profileUpdated);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        print('DEBUG: Profile update failed: ${result.message}');
        // If profile update failed and we uploaded an image, delete it
        if (newPhotoURL != null) {
          print('DEBUG: Deleting uploaded image due to profile update failure: $newPhotoURL');
          await _profileProvider.deleteProfileImage(newPhotoURL);
        }
        AuthHelpers.showErrorToast(result.message ?? 'Failed to update profile');
      }
    } catch (e) {
      AuthHelpers.showErrorToast('Failed to update profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _cancelChanges() {
    _profileProvider.clearSelectedImage();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authProvider.userData;
    
    return LoadingOverlay(
      isLoading: _isLoading || _authProvider.isLoading || _profileProvider.isUploading,
      message: _isLoading ? AuthConstants.updatingProfile : AuthConstants.uploadingImage,
      child: Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(AuthConstants.editProfile, 
              style: TextStyle(color: textPrimaryColor)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: iconPrimaryColor),
          actions: [
            if (_profileProvider.hasSelectedImage || 
                _displayNameController.text != (user?.displayName ?? '') ||
                _phoneNumberController.text != (user?.phoneNumber ?? '') ||
                _bioController.text != (user?.bio ?? ''))
              TextButton(
                onPressed: _cancelChanges,
                style: TextButton.styleFrom(foregroundColor: textSecondaryColor),
                child: Text(AuthConstants.cancel),
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AuthConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AuthConstants.largePadding),
                  
                  // Profile Image Section
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _selectProfileImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _profileProvider.hasSelectedImage 
                                        ? primaryColor 
                                        : profileImageBorderColor,
                                    width: _profileProvider.hasSelectedImage ? 4 : 3,
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
                                      } else if (user?.photoURL != null && 
                                                 user!.photoURL!.isNotEmpty) {
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
                              if (_profileProvider.hasSelectedImage)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AuthConstants.smallPadding),
                        TextButton(
                          onPressed: _selectProfileImage,
                          style: TextButton.styleFrom(
                            foregroundColor: linkColor,
                          ),
                          child: Text(_profileProvider.hasSelectedImage 
                              ? '${AuthConstants.changeProfileImage} (${AuthConstants.readyToSave})' 
                              : AuthConstants.changeProfileImage),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AuthConstants.largePadding),
                  
                  // Form Fields
                  Card(
                    color: cardColor,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(AuthConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AuthConstants.accountInfo,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: AuthConstants.defaultPadding),
                          
                          // Display Name Field
                          AuthTextField(
                            controller: _displayNameController,
                            label: AuthConstants.displayNameLabel,
                            hint: AuthConstants.displayNameHint,
                            prefixIcon: Icon(Icons.person, color: iconSecondaryColor),
                            errorText: _errors['displayName'],
                            onChanged: (value) => _validateForm(),
                            validator: (value) => AuthValidators.validateDisplayName(value),
                          ),
                          
                          const SizedBox(height: AuthConstants.defaultPadding),
                          
                          // Email Field (Read-only)
                          Container(
                            decoration: BoxDecoration(
                              color: inputDisabledColor,
                              borderRadius: BorderRadius.circular(AuthConstants.defaultRadius),
                              border: Border.all(color: inputBorderColor),
                            ),
                            child: ListTile(
                              leading: Icon(Icons.email, color: iconSecondaryColor),
                              title: Text(
                                AuthConstants.emailLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondaryColor,
                                ),
                              ),
                              subtitle: Text(
                                user?.email ?? '',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textPrimaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Icon(
                                Icons.lock,
                                color: iconSecondaryColor,
                                size: 16,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: AuthConstants.smallPadding),
                          Text(
                            'Email address cannot be changed after registration',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondaryColor,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          
                          const SizedBox(height: AuthConstants.defaultPadding),
                          
                          // Phone Number Field
                          AuthTextField(
                            controller: _phoneNumberController,
                            label: AuthConstants.phoneNumberLabel,
                            hint: AuthConstants.phoneNumberHint,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icon(Icons.phone, color: iconSecondaryColor),
                            errorText: _errors['phoneNumber'],
                            onChanged: (value) => _validateForm(),
                            validator: (value) => AuthValidators.validatePhoneNumber(value),
                          ),
                          
                          const SizedBox(height: AuthConstants.defaultPadding),
                          
                          // Bio Field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AuthTextField(
                                controller: _bioController,
                                label: AuthConstants.bioLabel,
                                hint: AuthConstants.bioHint,
                                maxLines: 3,
                                maxLength: 500,
                                prefixIcon: Icon(Icons.person_outline, color: iconSecondaryColor),
                                errorText: _errors['bio'],
                                onChanged: (value) => _validateForm(),
                                validator: (value) => AuthValidators.validateBio(value),
                              ),
                              const SizedBox(height: AuthConstants.smallPadding),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tell us about yourself',
                                    style: TextStyle(
                                      color: textSecondaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${_bioController.text.length}/500',
                                    style: TextStyle(
                                      color: _bioController.text.length > 450 
                                          ? errorColor 
                                          : textSecondaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: AuthConstants.largePadding),
                  
                  // Action Buttons
                  AuthButton(
                    text: AuthConstants.saveButton,
                    onPressed: _saveChanges,
                    icon: Icons.save,
                  ),
                  
                  const SizedBox(height: AuthConstants.defaultPadding),
                  
                  AuthButton(
                    text: AuthConstants.backButton,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icons.arrow_back,
                    backgroundColor: Colors.grey,
                    textColor: Colors.white,
                  ),
                  
                  const SizedBox(height: AuthConstants.extraLargePadding),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 