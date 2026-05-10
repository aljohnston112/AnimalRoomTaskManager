import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'user_repository.dart';

class UserListModel extends ChangeNotifier {
  final UserRepository _userRepository;

  late User _admin;

  late ValueListenable<Set<User>> users;
  late ValueListenable<Set<User>> whitelistedEmails;

  User get admin => _admin;

  UserListModel({required UserRepository userRepository})
    : _userRepository = userRepository {
    _admin = _userRepository.getAdmin();
    whitelistedEmails = _userRepository.emailWhitelistNotifier;
    users = _userRepository.users;
  }

  void addEmailToWhitelist(User user) {
    _userRepository.addEmailToWhitelist(user);
  }

  void updateUser(User user) {
    _userRepository.updateUserGroup(user);
  }

  void removeUser(User user) {
    _userRepository.removeUser(user);
  }

  void changeAdmin(User newAdmin) {
    _userRepository.changeAdmin(admin, newAdmin);
  }
}
