class AuthValidators {
  // Email validation
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? confirmPassword, String password) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (confirmPassword != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Display name validation
  static String? validateDisplayName(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) {
      return 'Display name is required';
    }
    
    if (displayName.trim().length < 2) {
      return 'Display name must be at least 2 characters long';
    }
    
    if (displayName.trim().length > 50) {
      return 'Display name must be less than 50 characters';
    }
    
    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return null; // Phone number is optional
    }
    
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    if (!phoneRegex.hasMatch(phoneNumber)) {
      return 'Please enter a valid phone number';
    }
    
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return 'Phone number must be between 10 and 15 digits';
    }
    
    return null;
  }

  // Current password validation
  static String? validateCurrentPassword(String? currentPassword) {
    if (currentPassword == null || currentPassword.isEmpty) {
      return 'Current password is required';
    }
    
    return null;
  }

  // New password validation
  static String? validateNewPassword(String? newPassword) {
    return validatePassword(newPassword);
  }

  // Login form validation
  static Map<String, String?> validateLoginForm({
    required String email,
    required String password,
  }) {
    return {
      'email': validateEmail(email),
      'password': validatePassword(password),
    };
  }

  // Registration form validation
  static Map<String, String?> validateRegistrationForm({
    required String email,
    required String password,
    required String confirmPassword,
    required String displayName,
    String? bio,
    String? phoneNumber,
  }) {
    return {
      'email': validateEmail(email),
      'password': validatePassword(password),
      'confirmPassword': validateConfirmPassword(confirmPassword, password),
      'displayName': validateDisplayName(displayName),
      'bio': validateBio(bio),
      'phoneNumber': validatePhoneNumber(phoneNumber),
    };
  }

  // Password change form validation
  static Map<String, String?> validatePasswordChangeForm({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) {
    return {
      'currentPassword': validateCurrentPassword(currentPassword),
      'newPassword': validatePassword(newPassword),
      'confirmNewPassword': validateConfirmPassword(confirmNewPassword, newPassword),
    };
  }

  // Profile update form validation
  static Map<String, String?> validateProfileForm({
    required String displayName,
    String? bio,
    String? phoneNumber,
  }) {
    return {
      'displayName': validateDisplayName(displayName),
      'bio': validateBio(bio),
      'phoneNumber': validatePhoneNumber(phoneNumber),
    };
  }

  // Check if form is valid
  static bool isFormValid(Map<String, String?> errors) {
    return errors.values.every((error) => error == null);
  }

  // Get password strength
  static PasswordStrength getPasswordStrength(String password) {
    int score = 0;
    
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    switch (score) {
      case 0:
      case 1:
        return PasswordStrength.weak;
      case 2:
      case 3:
        return PasswordStrength.fair;
      case 4:
        return PasswordStrength.good;
      case 5:
        return PasswordStrength.strong;
      default:
        return PasswordStrength.weak;
    }
  }

  // Get password strength color
  static int getPasswordStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 0xFFE57373; // Red
      case PasswordStrength.fair:
        return 0xFFFFB74D; // Orange
      case PasswordStrength.good:
        return 0xFFFFD54F; // Yellow
      case PasswordStrength.strong:
        return 0xFF81C784; // Green
    }
  }

  // Get password strength text
  static String getPasswordStrengthText(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.fair:
        return 'Fair';
      case PasswordStrength.good:
        return 'Good';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  // Bio validation
  static String? validateBio(String? bio) {
    if (bio == null || bio.isEmpty) {
      return null; // Bio is optional
    }
    
    if (bio.length > 500) {
      return 'Bio must be less than 500 characters';
    }
    
    // Check for inappropriate content (basic check)
    final inappropriateWords = ['profanity', 'inappropriate', 'spam'];
    final lowerBio = bio.toLowerCase();
    for (final word in inappropriateWords) {
      if (lowerBio.contains(word)) {
        return 'Bio contains inappropriate content';
      }
    }
    
    return null;
  }
}

enum PasswordStrength {
  weak,
  fair,
  good,
  strong,
} 