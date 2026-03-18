enum UserGroup { admin, principalInvestigator, roomChecker }

class User {
  final String email;
  final UserGroup group;

  const User({required this.email, required this.group});
  
  @override
  String toString() {
    return "$email: $group";
  }
}

class UserRepository {

  final List<User> _users = [
    User(email: "a@uwosh.edu", group: UserGroup.admin),
    User(email: "b@uwosh.edu", group: UserGroup.principalInvestigator),
    User(email: "c@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "d@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "e@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "f@uwosh.edu", group: UserGroup.principalInvestigator),
    User(email: "g@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "h@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "i@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "j@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "k@uwosh.edu", group: UserGroup.principalInvestigator),
    User(email: "l@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "m@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "n@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "o@uwosh.edu", group: UserGroup.principalInvestigator),
    User(email: "p@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "q@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "r@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "s@uwosh.edu", group: UserGroup.principalInvestigator),
    User(email: "t@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "u@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "v@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "w@uwosh.edu", group: UserGroup.principalInvestigator),
    User(email: "x@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "y@uwosh.edu", group: UserGroup.roomChecker),
    User(email: "z@uwosh.edu", group: UserGroup.roomChecker),
  ];

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
  }

  void removeUser(User user) {
    _users.remove(user);
  }

  void changeAdmin(User admin, User newAdmin) {
    updateUser(
      User(email: admin.email, group: UserGroup.principalInvestigator),
    );
    updateUser(
      User(email: newAdmin.email, group: UserGroup.admin),
    );
  }

}
