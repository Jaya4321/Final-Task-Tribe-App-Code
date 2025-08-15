class AuthConstants {
  // App branding
  static const String appName = 'TaskTribe';
  static const String appTagline = 'Organize your tasks, boost your productivity';
  
  // Authentication screens
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String signOut = 'Sign Out';
  static const String forgotPassword = 'Forgot Password';
  static const String resetPassword = 'Reset Password';
  static const String changePassword = 'Change Password';
  static const String createAccount = 'Create Account';
  static const String welcomeBack = 'Welcome back!';
  static const String welcomeMessage = 'Sign in to continue';
  static const String joinUs = 'Join us today!';
  static const String createAccountMessage = 'Create your account to get started';
  
  // Form labels
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Password';
  static const String confirmPasswordLabel = 'Confirm Password';
  static const String currentPasswordLabel = 'Current Password';
  static const String newPasswordLabel = 'New Password';
  static const String confirmNewPasswordLabel = 'Confirm New Password';
  static const String displayNameLabel = 'Display Name';
  static const String fullNameLabel = 'Full Name';
  static const String phoneNumberLabel = 'Phone Number';
  static const String bioLabel = 'Bio';
  
  // Form hints
  static const String emailHint = 'Enter your email address';
  static const String passwordHint = 'Enter your password';
  static const String confirmPasswordHint = 'Confirm your password';
  static const String currentPasswordHint = 'Enter your current password';
  static const String newPasswordHint = 'Enter your new password';
  static const String confirmNewPasswordHint = 'Confirm your new password';
  static const String displayNameHint = 'Enter your display name';
  static const String fullNameHint = 'Enter your full name';
  static const String phoneNumberHint = 'Enter your phone number';
  static const String bioHint = 'Tell us about yourself (optional)';
  
  // Buttons
  static const String loginButton = 'Sign In';
  static const String registerButton = 'Create Account';
  static const String resetButton = 'Send Reset Email';
  static const String changeButton = 'Change Password';
  static const String updateButton = 'Update Profile';
  static const String saveButton = 'Save Changes';
  static const String cancelButton = 'Cancel';
  static const String deleteButton = 'Delete Account';
  static const String confirmButton = 'Confirm';
  static const String backButton = 'Back';
  static const String nextButton = 'Next';
  static const String skipButton = 'Skip';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String back = 'Back';
  
  // Messages
  static const String loggingIn = 'Signing in...';
  static const String registering = 'Creating account...';
  static const String resettingPassword = 'Sending reset email...';
  static const String changingPassword = 'Changing password...';
  static const String updatingProfile = 'Updating profile...';
  static const String signingOut = 'Signing out...';
  static const String deletingAccount = 'Deleting account...';
  static const String uploadingImage = 'Uploading image...';
  static const String processing = 'Processing...';
  static const String loading = 'Loading...';
  static const String sendingEmail = 'Sending email...';
  
  // Success messages
  static const String loginSuccess = 'Successfully signed in!';
  static const String registerSuccess = 'Account created successfully!';
  static const String resetEmailSent = 'Password reset email sent!';
  static const String passwordChanged = 'Password changed successfully!';
  static const String profileUpdated = 'Profile updated successfully!';
  static const String signOutSuccess = 'Signed out successfully!';
  static const String accountDeleted = 'Account deleted successfully!';
  static const String imageUploaded = 'Image uploaded successfully!';
  
  // Error messages
  static const String loginFailed = 'Sign in failed';
  static const String incorrectCredentials = 'Incorrect email or password';
  static const String userNotFound = 'No user found with this email address';
  static const String tooManyAttempts = 'Too many failed attempts. Please try again later';
  static const String accountDisabled = 'This account has been disabled';
  static const String registerFailed = 'Account creation failed. Please try again.';
  static const String resetFailed = 'Failed to send reset email. Please try again.';
  static const String passwordChangeFailed = 'Failed to change password. Please try again.';
  static const String profileUpdateFailed = 'Failed to update profile. Please try again.';
  static const String signOutFailed = 'Sign out failed. Please try again.';
  static const String accountDeleteFailed = 'Failed to delete account. Please try again.';
  static const String imageUploadFailed = 'Failed to upload image. Please try again.';
  static const String networkError = 'Network error. Please check your connection.';
  static const String unknownError = 'An unexpected error occurred. Please try again.';
  
  // Validation messages
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Please enter a valid email address';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort = 'Password must be at least 8 characters';
  static const String passwordMismatch = 'Passwords do not match';
  static const String displayNameRequired = 'Display name is required';
  static const String displayNameTooShort = 'Display name must be at least 2 characters';
  static const String displayNameTooLong = 'Display name must be less than 50 characters';
  static const String bioTooLong = 'Bio must be less than 500 characters';
  static const String bioInappropriate = 'Bio contains inappropriate content';
  
  // Profile
  static const String profileTitle = 'Profile';
  static const String editProfile = 'Edit Profile';
  static const String accountInfo = 'Account Information';
  static const String accountActions = 'Account Actions';
  static const String memberSince = 'Member since';
  static const String lastLogin = 'Last login';
  static const String profileImage = 'Profile Image';
  static const String changeProfileImage = 'Change Profile Image';
  static const String removeProfileImage = 'Remove Profile Image';
  static const String saveProfileChanges = 'Save Profile Changes';
  static const String cancelChanges = 'Cancel Changes';
  static const String readyToSave = 'Ready to Save';
  static const String noChangesToSave = 'No changes to save';
  static const String changesCancelled = 'Changes cancelled';
  static const String profileImageReady = 'Profile image ready to upload';
  
  // Terms and conditions
  static const String termsAndConditions = 'Terms and Conditions';
  static const String privacyPolicy = 'Privacy Policy';
  static const String agreeToTerms = 'I agree to the Terms and Conditions';
  static const String agreeToPrivacy = 'I agree to the Privacy Policy';
  static const String termsRequired = 'You must agree to the terms and conditions';
  
  // Confirmation dialogs
  static const String deleteAccountTitle = 'Delete Account';
  static const String deleteAccountMessage = 'Are you sure you want to delete your account? This action cannot be undone.';
  static const String signOutTitle = 'Sign Out';
  static const String signOutMessage = 'Are you sure you want to sign out?';
  static const String discardChangesTitle = 'Discard Changes';
  static const String discardChangesMessage = 'Are you sure you want to discard your changes?';
  static const String deleteAccount = 'Delete Account';
  static const String confirmPasswordTitle = 'Confirm Password';
  static const String confirmPasswordMessage = 'Please enter your password to confirm account deletion:';
  static const String selectImageSourceTitle = 'Select Image Source';
  static const String galleryOption = 'Gallery';
  static const String cameraOption = 'Camera';
  
  // Validation constants
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minDisplayNameLength = 2;
  static const int maxDisplayNameLength = 50;
  
  // Spacing constants
  static const double smallPadding = 8.0;
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;
  
  // Border radius
  static const double smallRadius = 8.0;
  static const double defaultRadius = 12.0;
  static const double largeRadius = 16.0;
  
  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration defaultAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Image constants
  static const double profileImageSize = 120.0;
  static const double smallProfileImageSize = 80.0;
  static const double largeProfileImageSize = 150.0;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  
  // UI constants
  static const double buttonHeight = 48.0;
  static const double inputFieldHeight = 56.0;
  
  // Signup flow messages
  static const String accountCreatedImageUploadFailed = 'Account created but failed to upload profile image';
  static const String uploadingProfileImage = 'Uploading profile image...';
  static const String profileImageUploadSuccess = 'Profile image uploaded successfully';
  static const String profileImageUploadFailed = 'Failed to upload profile image';
} 