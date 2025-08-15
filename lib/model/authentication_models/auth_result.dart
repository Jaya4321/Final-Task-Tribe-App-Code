import 'user_model.dart';

class AuthResult {
  final bool success;
  final String? message;
  final String? errorCode;
  final dynamic data;

  const AuthResult({
    required this.success,
    this.message,
    this.errorCode,
    this.data,
  });

  factory AuthResult.success({String? message, dynamic data}) {
    return AuthResult(
      success: true,
      message: message,
      data: data,
    );
  }

  factory AuthResult.failure({required String message, String? errorCode}) {
    return AuthResult(
      success: false,
      message: message,
      errorCode: errorCode,
    );
  }

  // Getter for user data
  UserModel? get user {
    if (data is UserModel) {
      return data as UserModel;
    }
    return null;
  }

  @override
  String toString() {
    return 'AuthResult(success: $success, message: $message, errorCode: $errorCode)';
  }
} 