import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb show User;

import '../supabase_client/database.dart';

enum UserGroup { admin, principalInvestigatorOrChiefOfStaff, roomChecker }

class User {
  final String email;
  final UserGroup group;

  const User({required this.email, required this.group});

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
    ),
    User(email: "a@uwosh.edu", group: UserGroup.admin),
    User(
      email: "b@uwosh.edu",
      group: UserGroup.principalInvestigatorOrChiefOfStaff,
    ),
    User(email: "c@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "d@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "e@uwosh.edu", group: UserGroup.roomChecker),
    User(
      email: "f@uwosh.edu",
      group: UserGroup.principalInvestigatorOrChiefOfStaff,
    ),
    User(email: "g@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "h@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "i@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "j@uwosh.edu", group: UserGroup.roomChecker),
    User(
      email: "k@uwosh.edu",
      group: UserGroup.principalInvestigatorOrChiefOfStaff,
    ),
    User(email: "l@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "m@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "n@uwosh.edu", group: UserGroup.roomChecker),
    User(
      email: "o@uwosh.edu",
      group: UserGroup.principalInvestigatorOrChiefOfStaff,
    ),
    User(email: "p@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "q@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "r@uwosh.edu", group: UserGroup.roomChecker),
    User(
      email: "s@uwosh.edu",
      group: UserGroup.principalInvestigatorOrChiefOfStaff,
    ),
    User(email: "t@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "u@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "v@uwosh.edu", group: UserGroup.roomChecker),
    User(
      email: "w@uwosh.edu",
      group: UserGroup.principalInvestigatorOrChiefOfStaff,
    ),
    User(email: "x@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "y@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "z@uwosh.edu", group: UserGroup.roomChecker),
  ];

  UserRepository({required this.database});

  void subscribeToAuthEvents(void Function(User?) onAuthChange) {
    database.subscribeToAuth((data) async {
      switch (data.event) {
        case AuthChangeEvent.signedIn:
          var email = data.session?.user.email;
          var id = data.session?.user.id;
          if (email != null) {
            onAuthChange(
              User(email: email, group: await database.getUserGroup(email)),
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
      ),
    );
    updateUser(User(email: newAdmin.email, group: UserGroup.admin));
    notifyListeners();
  }

  /// Returns the user if they are authenticated, else null
  Future<void> tryLogIn(String email, String password) async {
    // TODO for dev only
    // await dotenv.load(fileName: ".env");
    // email = dotenv.get("DEV_EMAIL");
    // password = dotenv.get("DEV_PASSWORD");
    database.login(email: email, password: password);
  }

  Future<void> trySignUp(String email, String password) async {
    database.signUp(email: email, password: password);
  }
}
