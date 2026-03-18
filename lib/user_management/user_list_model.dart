import 'dart:collection';

import 'package:flutter/material.dart';

import 'user_repository.dart';

class UserListModel extends ChangeNotifier {
  final UserRepository _userRepository;

  late User _admin;

  User get admin => _admin;

  List<User> _users = [];

  UnmodifiableListView<User> get users => UnmodifiableListView(_users);

  UserListModel({required UserRepository userRepository})
      : _userRepository = userRepository {
    _admin = _userRepository.getAdmin();
    _users = _userRepository.getUsers();
  }

  void addUser(User user) {
    _users.add(user);
    if (user.group == UserGroup.admin) {
      _admin = user;
    }
    notifyListeners();
    _users = _userRepository.getUsers();
    _admin = _userRepository.getAdmin();
  }

  void updateUser(User user) {
    _users.removeWhere((u) {
      return u.email == user.email;
    });
    addUser(user);
    notifyListeners();
    _userRepository.updateUser(user);
  }

  void removeUser(User user) {
    _users.remove(user);
    notifyListeners();
    _userRepository.removeUser(user);
  }

  void changeAdmin(User newAdmin) {
    User oldAdmin = admin;
    _admin = newAdmin;
    notifyListeners();
    _userRepository.changeAdmin(oldAdmin, newAdmin);
    _users = _userRepository.getUsers();
    _admin = _userRepository.getAdmin();
  }
}
