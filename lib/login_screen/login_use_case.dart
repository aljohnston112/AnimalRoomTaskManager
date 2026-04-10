import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../user_management/user_repository.dart';

/// Provide the app with the current user
class LoginUseCase extends ChangeNotifier {
  final UserRepository _userRepository;

  User? _loggedInUser;

  LoginUseCase({required UserRepository userRepository})
    : _userRepository = userRepository;

  User? get loggedInUser => _loggedInUser;

  Future<void> login(String email) async {
    User? user = await _userRepository.tryLogIn(email);
    if (user != null) {
      _loggedInUser = user;
    } else {
      // TODO for testing only
      User newUser = User(
        email: email,
        group: UserGroup.principalInvestigatorOrChiefOfStaff,
      );
      _userRepository.addUser(newUser);
      _loggedInUser = newUser;
    }
    notifyListeners();
  }

  Future<void> signup(String email, String password) async {
    User? user = await _userRepository.trySignIn(email, password);
  }
}
