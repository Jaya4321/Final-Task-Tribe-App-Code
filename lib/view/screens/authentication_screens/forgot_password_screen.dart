import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controller/providers/authentication_providers/auth_provider.dart';
import '../../components/authentication_components/auth_text_field.dart';
import '../../components/authentication_components/auth_button.dart';
import '../../components/shared_components/loading_components.dart';
import '../../../constants/auth_constants.dart';
import '../../../constants/myColors.dart';
import '../../../utils/auth_validators.dart';
import '../../../utils/auth_helpers.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  Map<String, String?> _errors = {};

  late AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _errors = {
        'email': AuthValidators.validateEmail(_emailController.text),
      };
    });
  }

  Future<void> _handleResetPassword() async {
    _validateForm();
    
    if (!AuthValidators.isFormValid(_errors)) {
      return;
    }

    final result = await _authProvider.resetPassword(_emailController.text.trim());

    if (result.success && mounted) {
      AuthHelpers.showSuccessDialog(
        context: context,
        title: 'Email Sent',
        message: 'Password reset instructions have been sent to your email address. Please check your inbox and follow the instructions to reset your password.',
        buttonText: 'OK',
        onPressed: () {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pop(); // Go back to login
        },
      );
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _authProvider.isLoading,
      message: AuthConstants.sendingEmail,
      child: Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Forgot Password', style: TextStyle(color: textPrimaryColor)),
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
                    Icons.lock_reset,
                    size: 80,
                    color: primaryColor,
                  ),
                  const SizedBox(height: AuthConstants.defaultPadding),
                  
                  // Title
                  Text(
                    'Reset Password',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AuthConstants.defaultPadding),
                  
                  // Description
                  Text(
                    'Enter your email address and we\'ll send you a link to reset your password.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: AuthConstants.extraLargePadding),
                  
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
                    textInputAction: TextInputAction.done,
                  ),
                  
                  const SizedBox(height: AuthConstants.largePadding),
                  
                  // Reset Password Button
                  AuthButton(
                    text: AuthConstants.resetPassword,
                    onPressed: _handleResetPassword,
                    isLoading: _authProvider.isLoading,
                    isEnabled: AuthValidators.isFormValid(_errors),
                  ),
                  
                  const SizedBox(height: AuthConstants.largePadding),
                  
                  // Back to Login
                  AuthButton(
                    text: AuthConstants.back,
                    onPressed: _navigateToLogin,
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