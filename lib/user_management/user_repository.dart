import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_client/database.dart';

enum UserGroup { admin, principalInvestigatorOrChiefOfStaff, roomChecker }

String userGroupToString(UserGroup userGroup) {
  switch (userGroup) {
    case UserGroup.admin:
      return "Admin";
    case UserGroup.principalInvestigatorOrChiefOfStaff:
      return "Principal Investigator or Chief of Staff";
    case UserGroup.roomChecker:
      return "Student Worker or Staff";
  }
}

class User {
  final String email;
  final UserGroup group;
  final int? uid;

  const User({required this.email, required this.group, required this.uid});

  @override
  bool operator ==(Object other) => other is User && other.email == email;

  @override
  int get hashCode => email.hashCode;
}

class UserRepository {
  final Database _database;

  final ValueNotifier<Set<User>> emailWhitelistNotifier = ValueNotifier({});
  final ValueNotifier<Set<User>> usersNotifier = ValueNotifier({});

  final Set<User> _whitelistedUsers = {};
  final Set<User> _users = {};

  UserRepository({required Database database}) : _database = database {
    _database.subscribeToEmailWhitelist((p) {
      var map = p.newRecord;
      var user = parseWhitelistedEmail(map);
      _whitelistedUsers.remove(user);
      _whitelistedUsers.add(user);
      emailWhitelistNotifier.value = Set.from(_whitelistedUsers);
    });
    _database.subscribeToUsers((p) {
      var map = p.newRecord;
      User user = parseUser(map);
      _whitelistedUsers.removeWhere((u) => u.email == user.email);
      if (!map['deleted']) {
        // add does not replace
        _users.remove(user);
        _users.add(user);
      } else {
        _users.remove(user);
      }
      emailWhitelistNotifier.value = Set.from(_whitelistedUsers);
      usersNotifier.value = Set.from(_users);
    });
  }

  User parseWhitelistedEmail(Map<String, dynamic> map) {
    return User(
      email: map['email'],
      group: UserGroup.values[map['ug_id']],
      uid: null,
    );
  }

  User parseUser(Map<String, dynamic> map) {
    User user = User(
      email: map['name'],
      group: UserGroup.values[map['ug_id']],
      uid: map['u_id'],
    );
    return user;
  }

  void subscribeToAuthEvents(void Function(User?) onAuthChange) {
    _database.subscribeToAuth((data) async {
      switch (data.event) {
        case AuthChangeEvent.signedIn:
          var email = data.session?.user.email;
          var authId = data.session?.user.id;
          if (email != null && authId != null) {
            var user = await _database.getUserWithAuthId(authId);
            if (user != null) {
              _users.add(user);
              usersNotifier.value = Set.from(_users);
            }
            onAuthChange(user);
          } else {
            onAuthChange(null);
          }
          break;
        case AuthChangeEvent.signedOut:
          onAuthChange(null);
          break;
        default:
        // The other events are not relevant
      }
    });
  }

  Future<void> loadUsers() async {
    final whitelistedEmails = await _database.getWhitelistedEmails();
    for (final whitelistedEmail in whitelistedEmails) {
      _whitelistedUsers.add(parseWhitelistedEmail(whitelistedEmail));
    }
    emailWhitelistNotifier.value = Set.from(_whitelistedUsers);

    final users = await _database.getUsers();
    for (final user in users) {
      _users.add(parseUser(user));
    }
    usersNotifier.value = Set.from(_users);
  }

  Set<User> getWhitelistedEmails(){
    return _whitelistedUsers;
  }

  Set<User> getUsers() {
    return _users;
  }

  User getAdmin() {
    return _users.firstWhere((u) {
      return u.group == UserGroup.admin;
    });
  }

  Future<void> addEmailToWhitelist(User user) async {
    await _database.addUserToWhitelist(user);
  }

  Future<void> updateUserGroup(User user) async {
    await _database.updateUserGroup(user);
  }

  Future<void> removeUser(User user) async {
    await _database.removeUser(user);
  }

  Future<void> changeAdmin(User admin, User newAdmin) async {
    // TODO the new admin must not be switched until the new admin logs in
    // and the current admin must be logged out
    await updateUserGroup(
      User(email: newAdmin.email, group: UserGroup.admin, uid: newAdmin.uid),
    );
    await updateUserGroup(
      User(
        email: admin.email,
        group: UserGroup.principalInvestigatorOrChiefOfStaff,
        uid: admin.uid,
      ),
    );
  }

  /// Returns the user if they are authenticated, else null
  Future<bool> tryLogIn(String email, String password) async {
    return _database.login(email: email, password: password);
  }

  Future<bool> trySignUp(String email, String password) async {
    return _database.signUp(email: email, password: password);
  }
}
