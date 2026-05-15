import 'dart:collection';

import 'package:animal_room_task_manager/query/query_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as s;
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
  bool operator ==(Object other) => other is User && other.uid == uid;

  @override
  int get hashCode => email.hashCode;
}

class UserRepository {
  final Database _database;

  final Set<User> _emailWhitelist = {};
  late final RefreshableNotifier<UnmodifiableSetView<User>>
  _emailWhitelistNotifier = RefreshableNotifier(
    UnmodifiableSetView(_emailWhitelist),
  );
  late final ValueListenable<UnmodifiableSetView<User>> emailWhitelistNotifier =
      _emailWhitelistNotifier;

  final Set<User> _users = {};
  late final RefreshableNotifier<UnmodifiableSetView<User>> _usersNotifier =
      RefreshableNotifier(UnmodifiableSetView(_users));
  late final ValueListenable<UnmodifiableSetView<User>> usersNotifier =
      _usersNotifier;
  UnmodifiableSetView<User> get users => usersNotifier.value;

  UserRepository({required Database database}) : _database = database {
    _database.subscribeToEmailWhitelist((payload) {
      var newRecordMap = payload.newRecord;
      var user = parseWhitelistedEmailRecord(newRecordMap);
      _emailWhitelist.remove(user);
      if (!newRecordMap.containsKey('deleted') || !newRecordMap['deleted']) {
        _emailWhitelist.add(user);
      }
      _emailWhitelistNotifier.refresh();
    });

    _database.subscribeToUsers((payload) {
      var newRecordPayload = payload.newRecord;
      User user = parseUserRecord(newRecordPayload);
      _users.remove(user);
      if (!newRecordPayload.containsKey('deleted') ||
          !newRecordPayload['deleted']) {
        _users.add(user);
      }
      _usersNotifier.refresh();
    });
  }

  User parseWhitelistedEmailRecord(Map<String, dynamic> map) {
    return User(
      email: map['email'],
      group: UserGroup.values[map['ug_id']],
      uid: null,
    );
  }

  User parseUserRecord(Map<String, dynamic> map) {
    User user = User(
      email: map['name'],
      group: UserGroup.values[map['ug_id']],
      uid: map['u_id'],
    );
    return user;
  }

  Future<User?> getSessionUser() async {
    if (_database.isSessionValid()) {
      s.User? sessionUser = _database.getSessionUser();
      if (sessionUser != null) {
        return await _database.getUserWithAuthId(sessionUser.id);
      }
    }
    return null;
  }

  void subscribeToAuthEvents(void Function(User?) onAuthChange) {
    _database.subscribeToAuth((payload) async {
      switch (payload.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.initialSession:
          var session = payload.session;
          if (session != null) {
            var authId = session.user.id;
            var user = await _database.getUserWithAuthId(authId);
            if (user != null && !_users.contains(user)) {
              _users.add(user);
              _usersNotifier.refresh();
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
        // passwordRecovery
        // tokenRefreshed
        // userUpdated
        // mfaChallengeVerified
      }
    });
  }

  Future<void> loadUsers() async {
    final whitelistedEmails = await _database.getWhitelistedEmails();
    for (final whitelistedEmail in whitelistedEmails) {
      _emailWhitelist.add(parseWhitelistedEmailRecord(whitelistedEmail));
    }
    _emailWhitelistNotifier.refresh();

    final users = await _database.getUsers();
    for (final user in users) {
      _users.add(parseUserRecord(user));
    }
    _usersNotifier.refresh();
  }

  User getAdmin() {
    return _usersNotifier.value.firstWhere((user) {
      return user.group == UserGroup.admin;
    });
  }

  Future<void> addUserToWhitelist(User user) async {
    await _database.addUserToWhitelist(user);
  }

  Future<void> updateUserGroup(User user) async {
    await _database.updateUserGroup(user);
  }

  Future<void> removeUser(User user) async {
    await _database.removeUser(user);
  }

  Future<void> changeAdmin(User currentAdmin, User newAdmin) async {
    // TODO the new admin must not be switched until the new admin logs in
    // and the current admin must be logged out
    await updateUserGroup(
      User(email: newAdmin.email, group: UserGroup.admin, uid: newAdmin.uid),
    );
    await updateUserGroup(
      User(
        email: currentAdmin.email,
        group: UserGroup.principalInvestigatorOrChiefOfStaff,
        uid: currentAdmin.uid,
      ),
    );
  }

  /// Returns true if the log in succeeded
  Future<bool> tryLogIn(String email, String password) async {
    return _database.login(email: email, password: password);
  }

  /// Returns true if the sign up succeeded
  Future<bool> trySignUp(String email, String password) async {
    return _database.signUp(email: email, password: password);
  }
}
