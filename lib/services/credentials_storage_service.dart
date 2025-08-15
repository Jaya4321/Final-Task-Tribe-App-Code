import 'package:shared_preferences/shared_preferences.dart';

class CredentialsStorageService {
  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordKey = 'saved_password';

  // Save credentials
  static Future<void> saveCredentials({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (rememberMe) {
      await prefs.setBool(_rememberMeKey, true);
      await prefs.setString(_savedEmailKey, email);
      await prefs.setString(_savedPasswordKey, password);
      print('DEBUG: Credentials saved - Email: $email, RememberMe: true');
    } else {
      await prefs.setBool(_rememberMeKey, false);
      await prefs.remove(_savedEmailKey);
      await prefs.remove(_savedPasswordKey);
      print('DEBUG: Credentials cleared - RememberMe: false');
    }
  }

  // Get saved credentials
  static Future<Map<String, dynamic>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final savedEmail = prefs.getString(_savedEmailKey);
    final savedPassword = prefs.getString(_savedPasswordKey);

    print('DEBUG: Retrieved credentials - RememberMe: $rememberMe, Email: ${savedEmail != null ? 'exists' : 'null'}');

    return {
      'rememberMe': rememberMe,
      'email': savedEmail,
      'password': savedPassword,
    };
  }

  // Clear saved credentials
  static Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool(_rememberMeKey, false);
    await prefs.remove(_savedEmailKey);
    await prefs.remove(_savedPasswordKey);
  }

  // Check if remember me is enabled
  static Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }
} 