import 'package:flutter/material.dart';

import '../user_management/user_repository.dart';

/// Provide the app with the current user
class LoginUseCase extends ChangeNotifier {
  final UserRepository _userRepository;

  bool _isInitializing = true;
  User? _loggedInUser;

  LoginUseCase({required UserRepository userRepository})
    : _userRepository = userRepository {
    checkForActiveSession();
    userRepository.subscribeToAuthEvents((user) async {
      _loggedInUser = user;
      await userRepository.loadUsers();
      notifyListeners();
    });
  }

  bool get isInitializing => _isInitializing;

  User? get loggedInUser => _loggedInUser;

  Future<void> checkForActiveSession() async {
    User? user = await _userRepository.getSessionUser();
    if (user != null) {
      _loggedInUser = user;
      await _userRepository.loadUsers();
    }
    _isInitializing = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    return _userRepository.tryLogIn(email, password);
  }

  Future<bool> signup(String email, String password) async {
    return _userRepository.trySignUp(email, password);
  }
}
