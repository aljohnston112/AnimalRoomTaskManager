import 'package:flutter/material.dart';

import '../user_management/user_repository.dart';

/// Provide the app with the current user
class LoginUseCase extends ChangeNotifier {
  final UserRepository _userRepository;

  User? _loggedInUser;

  LoginUseCase({required UserRepository userRepository})
    : _userRepository = userRepository{
    userRepository.subscribeToAuthEvents((user) {
        _loggedInUser = user;
        notifyListeners();
    });
  }

  User? get loggedInUser => _loggedInUser;

  Future<void> login(String email, String password) async {
    _userRepository.tryLogIn(email, password);
  }

  Future<void> signup(String email, String password) async {
    _userRepository.trySignUp(email, password);
    // TODO need to add user to database table
  }
}
