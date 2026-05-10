import 'package:animal_room_task_manager/query/query_model.dart';
import 'package:flutter/src/foundation/change_notifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_client/database.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as s;

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

  final RefreshableNotifier<Set<User>> _emailWhitelistNotifier =
      RefreshableNotifier({});
  late final ValueListenable<Set<User>> emailWhitelistNotifier =
      _emailWhitelistNotifier;

  final RefreshableNotifier<Set<User>> _users = RefreshableNotifier({});
  late final ValueListenable<Set<User>> users = _users;

  UserRepository({required Database database}) : _database = database {
    _database.subscribeToEmailWhitelist((p) {
      var map = p.newRecord;
      var user = parseWhitelistedEmail(map);
      _emailWhitelistNotifier.value.remove(user);
      if (!map['deleted']) {
        _emailWhitelistNotifier.value.add(user);
      }
      _emailWhitelistNotifier.refresh();
    });
    _database.subscribeToUsers((p) {
      var map = p.newRecord;
      User user = parseUser(map);
      _users.value.remove(user);
      if (!map['deleted']) {
        _users.value.add(user);
      }
      _emailWhitelistNotifier.refresh();
      _users.refresh();
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

  Future<User?> getSessionUser() async {
    if (_database.isSessionValid()) {
      s.User? user = _database.getSessionUser();
      if (user != null) {
        return await _database.getUserWithAuthId(user.id);
      }
    }
    return null;
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
              _users.value.add(user);
              _users.refresh();
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
      _emailWhitelistNotifier.value.add(
        parseWhitelistedEmail(whitelistedEmail),
      );
    }
    _emailWhitelistNotifier.refresh();

    final users = await _database.getUsers();
    for (final user in users) {
      _users.value.add(parseUser(user));
    }
    _users.refresh();
  }

  User getAdmin() {
    return _users.value.firstWhere((u) {
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
