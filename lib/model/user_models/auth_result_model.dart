

import 'package:task_tribe_app/model/authentication_models/user_model.dart';

class AuthResult {
  final bool success;
  final String? message;
  final UserModel? user;
  final String? errorCode;

  AuthResult({
    required this.success,
    this.message,
    this.user,
    this.errorCode,
  });

  // Factory constructor for successful authentication
  factory AuthResult.success({
    String? message,
    UserModel? user,
  }) {
    return AuthResult(
      success: true,
      message: message,
      user: user,
    );
  }

  // Factory constructor for failed authentication
  factory AuthResult.error({
    required String message,
    String? errorCode,
  }) {
    return AuthResult(
      success: false,
      message: message,
      errorCode: errorCode,
    );
  }

  @override
  String toString() {
    return 'AuthResult(success: $success, message: $message, user: $user, errorCode: $errorCode)';
  }
} 