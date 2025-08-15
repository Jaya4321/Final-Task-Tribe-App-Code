import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controller/providers/authentication_providers/auth_provider.dart';
import '../../../controller/providers/authentication_providers/profile_provider.dart';
import '../../components/authentication_components/auth_text_field.dart';
import '../../components/authentication_components/password_field.dart';
import '../../components/authentication_components/auth_button.dart';
import '../../components/shared_components/loading_components.dart';
import '../../../constants/auth_constants.dart';
import '../../../constants/myColors.dart';
import '../../../utils/auth_validators.dart';
import '../../../utils/auth_helpers.dart';
import '../main_screens/main_navigation_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _bioController = TextEditingController();
  
  Map<String, String?> _errors = {};

  late AuthProvider _authProvider;
  late ProfileProvider _profileProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _profileProvider = Provider.of<ProfileProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneNumberController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _errors = AuthValidators.validateRegistrationForm(
        displayName: _displayNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        bio: _bioController.text,
        phoneNumber: _phoneNumberController.text,
      );
    });
  }

  Future<void> _handleSignup() async {
    _validateForm();
    
    if (!AuthValidators.isFormValid(_errors)) {
      return;
    }

    try {
      // Create the user account first (without image)
      final result = await _authProvider.registerWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
        photoURL: null, // Don't upload image yet
        phoneNumber: _phoneNumberController.text.trim(),
        bio: _bioController.text.trim(),
      );

      if (!result.success) {
        return; // Error message is already shown by the provider
      }

      // If user creation was successful and user has selected an image, upload it now
      if (result.success && _profileProvider.hasSelectedImage) {
        try {
          final photoURL = await _profileProvider.uploadProfileImage(result.user!.uid);
          
          if (photoURL != null) {
            // Update the user profile with the image URL
            await _authProvider.updateProfile(photoURL: photoURL);
          }
        } catch (e) {
          // Don't fail the signup process for image upload errors
          print('Error uploading profile image: $e');
        }
      }

      if (result.success && mounted) {
        // Clear the selected image
        _profileProvider.clearSelectedImage();
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainNavigationScreen(),
          ),
        );
      }
    } catch (e) {
      AuthHelpers.showErrorToast('An unexpected error occurred: $e');
    }
  }

  void _selectProfileImage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _profileProvider.selectImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
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

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _authProvider.isLoading || _profileProvider.isUploading,
      message: _authProvider.isLoading 
          ? AuthConstants.registering 
          : AuthConstants.uploadingProfileImage,
      child: Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Create Account', style: TextStyle(color: textPrimaryColor)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: iconPrimaryColor),
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
                                  }
                                  return Container(
                                    color: profileImagePlaceholderColor,
                                    child: Icon(
                                      Icons.person_add,
                                      size: 50,
                                      color: primaryColor,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AuthConstants.smallPadding),
                        TextButton(
                          onPressed: _selectProfileImage,
                          style: TextButton.styleFrom(
                            foregroundColor: linkColor,
                          ),
                          child: const Text('Add Profile Picture'),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AuthConstants.largePadding),
                  
                  // Display Name Field
                  AuthTextField(
                    label: AuthConstants.displayNameLabel,
                    hint: AuthConstants.displayNameHint,
                    controller: _displayNameController,
                    prefixIcon: Icon(Icons.person_outline, color: iconSecondaryColor),
                    errorText: _errors['displayName'],
                    onChanged: (value) => _validateForm(),
                    validator: (value) => AuthValidators.validateDisplayName(value),
                  ),
                  
                  const SizedBox(height: AuthConstants.defaultPadding),
                  
                  // Email Field
                  AuthTextField(
                    label: AuthConstants.emailLabel,
                    hint: AuthConstants.emailHint,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icon(Icons.email_outlined, color: iconSecondaryColor),
                    errorText: _errors['email'],
                    onChanged: (value) => _validateForm(),
                    validator: (value) => AuthValidators.validateEmail(value),
                  ),
                  
                  const SizedBox(height: AuthConstants.defaultPadding),
                  
                  // Password Field
                  PasswordField(
                    label: AuthConstants.passwordLabel,
                    hint: AuthConstants.passwordHint,
                    controller: _passwordController,
                    errorText: _errors['password'],
                    onChanged: (value) => _validateForm(),
                    showStrengthIndicator: true,
                  ),
                  
                  const SizedBox(height: AuthConstants.defaultPadding),
                  
                  // Confirm Password Field
                  PasswordField(
                    label: AuthConstants.confirmPasswordLabel,
                    hint: AuthConstants.confirmPasswordHint,
                    controller: _confirmPasswordController,
                    errorText: _errors['confirmPassword'],
                    onChanged: (value) => _validateForm(),
                  ),
                  
                  const SizedBox(height: AuthConstants.defaultPadding),
                  
                  // Phone Number Field (Optional)
                  AuthTextField(
                    label: AuthConstants.phoneNumberLabel,
                    hint: AuthConstants.phoneNumberHint,
                    controller: _phoneNumberController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icon(Icons.phone_outlined, color: iconSecondaryColor),
                    errorText: _errors['phoneNumber'],
                    onChanged: (value) => _validateForm(),
                    validator: (value) => AuthValidators.validatePhoneNumber(value),
                  ),
                  
                  const SizedBox(height: AuthConstants.defaultPadding),
                  
                  // Bio Field (Optional)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthTextField(
                        label: AuthConstants.bioLabel,
                        hint: AuthConstants.bioHint,
                        controller: _bioController,
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
                            'Optional - Tell us about yourself',
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
                  
                  const SizedBox(height: AuthConstants.largePadding),
                  
                  // Sign Up Button
                  AuthButton(
                    text: AuthConstants.signUp,
                    onPressed: _handleSignup,
                    isLoading: _authProvider.isLoading,
                    isEnabled: AuthValidators.isFormValid(_errors),
                  ),
                  
                  const SizedBox(height: AuthConstants.largePadding),
                  
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(color: textSecondaryColor),
                      ),
                      TextButton(
                        onPressed: _navigateToLogin,
                        style: TextButton.styleFrom(
                          foregroundColor: linkColor,
                        ),
                        child: const Text('Sign In'),
                      ),
                    ],
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