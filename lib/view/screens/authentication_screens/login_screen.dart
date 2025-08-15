import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controller/providers/authentication_providers/auth_provider.dart';
import '../../components/authentication_components/auth_text_field.dart';
import '../../components/authentication_components/password_field.dart';
import '../../components/authentication_components/auth_button.dart';
import '../../../constants/auth_constants.dart';
import '../../../constants/myColors.dart';
import '../../../utils/auth_validators.dart';
import '../main_screens/main_navigation_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  Map<String, String?> _errors = {};

  late AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Load saved credentials
  Future<void> _loadSavedCredentials() async {
    try {
      final savedCredentials = await _authProvider.getSavedCredentials();
      
      // Check if remember me is enabled and credentials exist
      if (savedCredentials['rememberMe'] == true && 
          savedCredentials['email'] != null && 
          savedCredentials['email']!.isNotEmpty &&
          savedCredentials['password'] != null && 
          savedCredentials['password']!.isNotEmpty) {
        
        setState(() {
          _rememberMe = true;
          _emailController.text = savedCredentials['email']!;
          _passwordController.text = savedCredentials['password']!;
        });
        
        // Show a brief message that credentials were loaded
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved credentials loaded'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // If remember me is not enabled or credentials are empty, clear the checkbox
        setState(() {
          _rememberMe = false;
        });
      }
    } catch (e) {
      // On error, ensure remember me is unchecked
      setState(() {
        _rememberMe = false;
      });
    }
  }

  void _validateForm() {
    setState(() {
      _errors = AuthValidators.validateLoginForm(
        email: _emailController.text,
        password: _passwordController.text,
      );
    });
  }

  void _clearAuthError() {
    if (_authProvider.errorMessage != null && _authProvider.errorMessage!.isNotEmpty) {
      _authProvider.clearError();
    }
  }

  Future<void> _handleLogin() async {
    _validateForm();
    
    if (!AuthValidators.isFormValid(_errors)) {
      return;
    }

    final result = await _authProvider.loginWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (result.success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(),
        ),
      );
    }
  }

  void _navigateToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SignupScreen(),
      ),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AuthConstants.defaultPadding),
          child: Form(
            key: _formKey,
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AuthConstants.extraLargePadding),
                    
                    // App Logo/Title
                    Image.asset('assets/images/rounded logo.png', width: 100, height: 100),
                    const SizedBox(height: AuthConstants.defaultPadding),
                    Text(
                      'TaskTribe',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AuthConstants.defaultPadding),
                    Text(
                      'Welcome back! Sign in to continue',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: AuthConstants.extraLargePadding),
                    
                    // Error Message Display
                    if (authProvider.errorMessage != null && authProvider.errorMessage!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(AuthConstants.defaultPadding),
                        margin: const EdgeInsets.only(bottom: AuthConstants.defaultPadding),
                        decoration: BoxDecoration(
                          color: errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: errorColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: errorColor, size: 20),
                            const SizedBox(width: AuthConstants.smallPadding),
                            Expanded(
                              child: Text(
                                authProvider.errorMessage!,
                                style: TextStyle(color: errorColor, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Email Field
                    AuthTextField(
                      label: AuthConstants.emailLabel,
                      hint: AuthConstants.emailHint,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icon(Icons.email_outlined, color: iconSecondaryColor),
                      errorText: _errors['email'],
                      onChanged: (value) {
                        _validateForm();
                        _clearAuthError();
                      },
                      validator: (value) => AuthValidators.validateEmail(value),
                    ),
                    
                    const SizedBox(height: AuthConstants.defaultPadding),
                    
                    // Password Field
                    PasswordField(
                      label: AuthConstants.passwordLabel,
                      hint: AuthConstants.passwordHint,
                      controller: _passwordController,
                      errorText: _errors['password'],
                      onChanged: (value) {
                        _validateForm();
                        _clearAuthError();
                      },
                    ),
                    
                    const SizedBox(height: AuthConstants.defaultPadding),
                    
                    // Remember Me & Forgot Password
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                            
                            // Clear saved credentials if remember me is unchecked
                            if (!_rememberMe) {
                              _authProvider.clearSavedCredentials();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Saved credentials cleared'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          activeColor: primaryColor,
                        ),
                        Text(
                          'Remember me',
                          style: TextStyle(color: textPrimaryColor),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _navigateToForgotPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: linkColor,
                          ),
                          child: const Text('Forgot Password?'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AuthConstants.largePadding),
                    
                    // Login Button
                    AuthButton(
                      text: AuthConstants.signIn,
                      onPressed: _handleLogin,
                      isLoading: authProvider.isLoading,
                      isEnabled: AuthValidators.isFormValid(_errors),
                    ),
                    
                    const SizedBox(height: AuthConstants.largePadding),
                    
                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(color: textSecondaryColor),
                        ),
                        TextButton(
                          onPressed: _navigateToSignUp,
                          style: TextButton.styleFrom(
                            foregroundColor: linkColor,
                          ),
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AuthConstants.extraLargePadding),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}