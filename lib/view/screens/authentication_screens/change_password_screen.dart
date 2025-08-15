import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controller/providers/authentication_providers/auth_provider.dart';
import '../../../controller/providers/authentication_providers/password_provider.dart';
import '../../components/authentication_components/password_field.dart';
import '../../components/authentication_components/auth_button.dart';
import '../../components/shared_components/loading_components.dart';
import '../../../constants/auth_constants.dart';
import '../../../constants/myColors.dart';
import '../../../utils/auth_validators.dart';
import '../../../utils/auth_helpers.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, String?> _errors = {};

  late AuthProvider _authProvider;
  late PasswordProvider _passwordProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _passwordProvider = Provider.of<PasswordProvider>(context, listen: false);
  }

  void _validateForm() {
    setState(() {
      _errors = AuthValidators.validatePasswordChangeForm(
        currentPassword: _passwordProvider.currentPasswordController.text,
        newPassword: _passwordProvider.newPasswordController.text,
        confirmNewPassword: _passwordProvider.confirmPasswordController.text,
      );
    });
  }

  Future<void> _handleChangePassword() async {
    _validateForm();
    
    if (!AuthValidators.isFormValid(_errors)) {
      return;
    }

    final result = await _authProvider.changePassword(
      _passwordProvider.currentPasswordController.text,
      _passwordProvider.newPasswordController.text,
    );

    if (result.success && mounted) {
      AuthHelpers.showSuccessDialog(
        context: context,
        title: 'Password Changed',
        message: 'Your password has been successfully updated.',
        buttonText: 'OK',
        onPressed: () {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pop(); // Go back to profile
        },
      );
    }
  }

  void _navigateBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _authProvider.isLoading,
      message: AuthConstants.changingPassword,
      child: Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Change Password', style: TextStyle(color: textPrimaryColor)),
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
                  const SizedBox(height: AuthConstants.extraLargePadding),
                  
                  // Icon
                  Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: primaryColor,
                  ),
                  const SizedBox(height: AuthConstants.defaultPadding),
                  
                  // Title
                  Text(
                    'Change Password',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AuthConstants.defaultPadding),
                  
                  // Description
                  Text(
                    'Enter your current password and choose a new password.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: AuthConstants.extraLargePadding),
                  
                  // Current Password Field
                  PasswordField(
                    label: AuthConstants.currentPasswordLabel,
                    hint: AuthConstants.currentPasswordHint,
                    controller: _passwordProvider.currentPasswordController,
                    errorText: _errors['currentPassword'],
                    onChanged: (value) => _validateForm(),
                    validator: (value) => AuthValidators.validateCurrentPassword(value),
                  ),
                  
                  const SizedBox(height: AuthConstants.defaultPadding),
                  
                  // New Password Field
                  PasswordField(
                    label: AuthConstants.newPasswordLabel,
                    hint: AuthConstants.newPasswordHint,
                    controller: _passwordProvider.newPasswordController,
                    errorText: _errors['newPassword'],
                    onChanged: (value) => _validateForm(),
                    showStrengthIndicator: true,
                  ),
                  
                  const SizedBox(height: AuthConstants.defaultPadding),
                  
                  // Confirm New Password Field
                  PasswordField(
                    label: AuthConstants.confirmNewPasswordLabel,
                    hint: AuthConstants.confirmNewPasswordHint,
                    controller: _passwordProvider.confirmPasswordController,
                    errorText: _errors['confirmNewPassword'],
                    onChanged: (value) => _validateForm(),
                  ),
                  
                  const SizedBox(height: AuthConstants.largePadding),
                  
                  // Change Password Button
                  AuthButton(
                    text: AuthConstants.changePassword,
                    onPressed: _handleChangePassword,
                    isLoading: _authProvider.isLoading,
                    isEnabled: AuthValidators.isFormValid(_errors),
                  ),
                  
                  const SizedBox(height: AuthConstants.largePadding),
                  
                  // Cancel Button
                  AuthButton(
                    text: AuthConstants.cancel,
                    onPressed: _navigateBack,
                    isEnabled: !_authProvider.isLoading,
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