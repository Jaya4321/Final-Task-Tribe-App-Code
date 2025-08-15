

import 'package:flutter/material.dart';

class LoginProvider with ChangeNotifier {
  String _username = '';
  String _password = '';
  bool _isLoading = false;

  String get username => _username;
  String get password => _password;
  
  bool get isLoading => _isLoading;
  


  void setUsername(String username) {
    _username = username;
    notifyListeners();
  }

  void setPassword(String password) {
    _password = password;
    notifyListeners();
  }

  Future<void> login(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    // Simulate a login delay
    await Future.delayed(Duration(seconds: 2));

    _isLoading = false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Login Sucess")),
    );
    notifyListeners();

    // Perform login logic here, such as API calls
  }
}