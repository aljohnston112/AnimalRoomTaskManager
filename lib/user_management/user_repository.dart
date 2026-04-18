import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_client/database.dart';

enum UserGroup { admin, principalInvestigatorOrChiefOfStaff, roomChecker }

class User {
  final String email;
  final UserGroup group;
  final int? uid;

  const User({required this.email, required this.group, required this.uid});

  @override
  String toString() {
    return "$email: $group";
  }
}

class UserRepository extends ChangeNotifier {
  final Database database;

  final List<User> _users = [
    User(
      email: "test@uwosh.edu",
      group: UserGroup.principalInvestigatorOrChiefOfStaff,
      uid: null,
    ),
    User(email: "a@uwosh.edu", group: UserGroup.admin, uid: null),
    User(
      email: "b@uwosh.edu",
      group: UserGroup.principalInvestigatorOrChiefOfStaff,
      uid: null,
    ),
    User(email: "c@uwosh.edu", group: UserGroup.roomChecker, uid: null),
    User(email: "d@uwosh.edu", group: UserGroup.roomChecker, uid: null),
    User(email: "e@uwosh.edu", group: UserGroup.roomChecker, uid: null),
    User(
      email: "f@uwosh.edu",
      group: UserGroup.principalInvestigatorOrChiefOfStaff,
      uid: null,
    ),
    User(email: "g@uwosh.edu", group: UserGroup.roomChecker, uid: null),
    User(email: "h@uwosh.edu", group: UserGroup.roomChecker, uid: null),
    User(email: "i@uwosh.edu", group: UserGroup.roomChecker, uid: null),
    User(email: "j@uwosh.edu", group: UserGroup.roomChecker, uid: null),
    User(
      email: "k@uwosh.edu",
      group: UserGroup.principalInvestigatorOrChiefOfStaff,
      uid: null,
    ),
    User(email: "l@uwosh.edu", group: UserGroup.roomChecker, uid: null),
    User(email: "m@uwosh.edu", group: UserGroup.roomChecker, uid: null),
    User(email: "n@uwosh.edu", group: UserGroup.roomChecker, uid: null),
    User(
      email: "o@uwosh.edu",
      group: UserGroup.principalInvestigatorOrChiefOfStaff,
      uid: null,
    ),
    User(email: "p@uwosh.edu", group: UserGroup.roomChecker, uid: null),
    User(email: "q@uwosh.edu", group: UserGroup.roomChecker, uid: null),
    User(email: "r@uwosh.edu", group: UserGroup.roomChecker, uid: null),
    User(
      email: "s@uwosh.edu",
      group: UserGroup.principalInvestigatorOrChiefOfStaff,
      uid: null,
    ),
    User(email: "t@uwosh.edu", group: UserGroup.roomChecker, uid: null),
    User(email: "u@uwosh.edu", group: UserGroup.roomChecker, uid: null),
    User(email: "v@uwosh.edu", group: UserGroup.roomChecker, uid: null),
    User(
      email: "w@uwosh.edu",
      group: UserGroup.principalInvestigatorOrChiefOfStaff,
      uid: null,
    ),
    User(email: "x@uwosh.edu", group: UserGroup.roomChecker, uid: null),
    User(email: "y@uwosh.edu", group: UserGroup.roomChecker, uid: null),
    User(email: "z@uwosh.edu", group: UserGroup.roomChecker, uid: null),
  ];

  UserRepository({required this.database});

  void subscribeToAuthEvents(void Function(User?) onAuthChange) {
    database.subscribeToAuth((data) async {
      switch (data.event) {
        case AuthChangeEvent.signedIn:
          var email = data.session?.user.email;
          var authId = data.session?.user.id;
          if (email != null && authId != null) {
            // TODO pull group and authID in one call
            onAuthChange(
              User(
                email: email,
                group: await database.getUserGroup(email),
                uid: await database.getUserWithAuthId(authId),
              ),
            );
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

  List<User> getUsers() {
    return _users;
  }

  User getAdmin() {
    getUsers();
    return _users.singleWhere((u) {
      return u.group == UserGroup.admin;
    });
  }

  void addUser(User user) {
    _users.add(user);
  }

  void updateUser(User user) {
    _users.removeWhere((u) {
      return u.email == user.email;
    });
    addUser(user);
    notifyListeners();
  }

  void removeUser(User user) {
    _users.remove(user);
    notifyListeners();
  }

  void changeAdmin(User admin, User newAdmin) {
    updateUser(
      User(
        email: admin.email,
        group: UserGroup.principalInvestigatorOrChiefOfStaff,
        uid: admin.uid,
      ),
    );
    updateUser(
      User(email: newAdmin.email, group: UserGroup.admin, uid: newAdmin.uid),
    );
    notifyListeners();
  }

  /// Returns the user if they are authenticated, else null
  Future<bool> tryLogIn(String email, String password) async {
    return database.login(email: email, password: password);
  }

  Future<void> trySignUp(String email, String password) async {
    database.signUp(email: email, password: password);
  }
}
