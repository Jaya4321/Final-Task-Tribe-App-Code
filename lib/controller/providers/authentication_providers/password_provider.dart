import 'package:flutter/material.dart';
import '../../../utils/auth_validators.dart';
import '../../../constants/auth_constants.dart';

class PasswordProvider with ChangeNotifier {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  Map<String, String?> _errors = {};

  // Getters
  TextEditingController get currentPasswordController => _currentPasswordController;
  TextEditingController get newPasswordController => _newPasswordController;
  TextEditingController get confirmPasswordController => _confirmPasswordController;
  
  bool get isCurrentPasswordVisible => _isCurrentPasswordVisible;
  bool get isNewPasswordVisible => _isNewPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;
  bool get isLoading => _isLoading;
  Map<String, String?> get errors => _errors;

  // Password strength
  PasswordStrength get passwordStrength => 
      AuthValidators.getPasswordStrength(_newPasswordController.text);

  String get passwordStrengthMessage => 
      AuthValidators.getPasswordStrengthText(passwordStrength);

  int get passwordStrengthColor => 
      AuthValidators.getPasswordStrengthColor(passwordStrength);

  // Toggle password visibility
  void toggleCurrentPasswordVisibility() {
    _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
    notifyListeners();
  }

  void toggleNewPasswordVisibility() {
    _isNewPasswordVisible = !_isNewPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners();
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Validate form
  void validateForm() {
    _errors = AuthValidators.validatePasswordChangeForm(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmNewPassword: _confirmPasswordController.text,
    );
    notifyListeners();
  }

  // Validate current password
  void validateCurrentPassword() {
    _errors['currentPassword'] = AuthValidators.validateCurrentPassword(_currentPasswordController.text);
    notifyListeners();
  }

  // Validate new password
  void validateNewPassword() {
    _errors['newPassword'] = AuthValidators.validatePassword(_newPasswordController.text);
    notifyListeners();
  }

  // Validate confirm password
  void validateConfirmPassword() {
    _errors['confirmNewPassword'] = AuthValidators.validateConfirmPassword(
      _confirmPasswordController.text,
      _newPasswordController.text,
    );
    notifyListeners();
  }

  // Check if form is valid
  bool get isFormValid => AuthValidators.isFormValid(_errors);

  // Get current password
  String get currentPassword => _currentPasswordController.text;

  // Get new password
  String get newPassword => _newPasswordController.text;

  // Get confirm password
  String get confirmPassword => _confirmPasswordController.text;

  // Clear form
  void clearForm() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _errors.clear();
    _isCurrentPasswordVisible = false;
    _isNewPasswordVisible = false;
    _isConfirmPasswordVisible = false;
    notifyListeners();
  }

  // Set error
  void setError(String field, String error) {
    _errors[field] = error;
    notifyListeners();
  }

  // Clear error
  void clearError(String field) {
    _errors.remove(field);
    notifyListeners();
  }

  // Clear all errors
  void clearAllErrors() {
    _errors.clear();
    notifyListeners();
  }

  // Check if passwords match
  bool get passwordsMatch => 
      _newPasswordController.text == _confirmPasswordController.text;

  // Check if new password is different from current
  bool get isNewPasswordDifferent => 
      _newPasswordController.text != _currentPasswordController.text;

  // Get password requirements met
  Map<String, bool> get passwordRequirements {
    final password = _newPasswordController.text;
    return {
      'length': password.length >= AuthConstants.minPasswordLength,
      'uppercase': password.contains(RegExp(r'[A-Z]')),
      'lowercase': password.contains(RegExp(r'[a-z]')),
      'number': password.contains(RegExp(r'\d')),
      'special': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
  }

  // Check if all password requirements are met
  bool get allPasswordRequirementsMet {
    final requirements = passwordRequirements;
    return requirements.values.every((met) => met);
  }

  // Get password requirement messages
  Map<String, String> get passwordRequirementMessages {
    return {
      'length': 'At least ${AuthConstants.minPasswordLength} characters',
      'uppercase': 'One uppercase letter',
      'lowercase': 'One lowercase letter',
      'number': 'One number',
      'special': 'One special character',
    };
  }

  // Get form data
  Map<String, String> getFormData() {
    return {
      'currentPassword': _currentPasswordController.text,
      'newPassword': _newPasswordController.text,
      'confirmPassword': _confirmPasswordController.text,
    };
  }

  // Get password strength text
  String getPasswordStrengthText() {
    return AuthValidators.getPasswordStrengthText(passwordStrength);
  }

  // Reset to initial state
  void reset() {
    clearForm();
    setLoading(false);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
} 