import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'user_repository.dart';

class UserListModel extends ChangeNotifier {
  final UserRepository _userRepository;

  late User _admin;

  late ValueListenable<UnmodifiableSetView<User>> usersNotifier;

  UnmodifiableSetView<User> get users => usersNotifier.value;

  User get admin => _admin;

  UserListModel({required UserRepository userRepository})
    : _userRepository = userRepository {
    _admin = _userRepository.getAdmin();
    usersNotifier = _userRepository.usersNotifier;
  }

  void addEmailToWhitelist(User user) {
    _userRepository.addUserToWhitelist(user);
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
