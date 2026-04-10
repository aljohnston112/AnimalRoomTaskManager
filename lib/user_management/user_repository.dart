import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  Future<User?> tryLogIn(String email) async {
    // TODO other users / sign up
    // await dotenv.load(fileName: ".env");
    // final result = await database.login(
    //   email: dotenv.get("DEV_EMAIL"),
    //   password: dotenv.get("DEV_PASSWORD"),
    // );
    // final result = await database.login(
    //   email: "fake",
    //   password: "fake",
    // );
    // print(result);
    // database.getRoomCheckSlots();

    var whereUserEmailMatches = _users.where((user) => user.email == email);
    if (whereUserEmailMatches.isNotEmpty) {
      return whereUserEmailMatches.first;
    }
    return null;
  }

  Future<User?> trySignIn(String email, String password) async {
    final User res = await database.signUp(
      email: email,
      password: password,
    );
  }
}
