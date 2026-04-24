import 'dart:collection';

import 'package:flutter/material.dart';

import 'user_repository.dart';

class UserListModel extends ChangeNotifier {
  final UserRepository _userRepository;

  late User _admin;

  User get admin => _admin;

  Set<User> _users = {};
  Set<User> _whitelistedEmails = {};

  UnmodifiableListView<User> get users => UnmodifiableListView(_users.union(_whitelistedEmails));

  UserListModel({required UserRepository userRepository})
    : _userRepository = userRepository {
    _admin = _userRepository.getAdmin();
    _whitelistedEmails = _userRepository.getWhitelistedEmails();
    _users = _userRepository.getUsers();
    _userRepository.emailWhitelistNotifier.addListener(() {
      _whitelistedEmails = _userRepository.emailWhitelistNotifier.value;
      notifyListeners();
    });
    _userRepository.usersNotifier.addListener(() {
      _users = _userRepository.usersNotifier.value;
      notifyListeners();
    });
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
