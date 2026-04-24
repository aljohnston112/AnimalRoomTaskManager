import 'package:animal_room_task_manager/theme_data.dart';
import 'package:flutter/material.dart';

import 'user_repository.dart';

class AddNewUserPage extends StatefulWidget {
  final String? user;
  final UserGroup? userGroup;
  final String title;

  const AddNewUserPage(this.title, this.user, this.userGroup, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _AddNewUserState(title: title);
  }
}

class _AddNewUserState extends State<AddNewUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final String title;
  UserGroup? selectedGroup;

  _AddNewUserState({required this.title});

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _emailController.text = widget.user!;
    }
    selectedGroup = widget.userGroup;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: buildScaffold(
        title: title,
        child: Center(
          child: constrainToPhoneWidth(
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextFormField(controller: _emailController, enabled: false),
                _buildUserGroupDropdown(),
                _buildAddUserButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DropdownButtonFormField<UserGroup> _buildUserGroupDropdown() {
    return DropdownButtonFormField<UserGroup>(
      decoration: InputDecoration(hintText: title),
      items: UserGroup.values
          .where((group) {
            return group != UserGroup.admin;
          })
          .map((group) {
            return DropdownMenuItem(
              value: group,
              child: Text(userGroupToString(group)),
            );
          })
          .toList(),
      initialValue: selectedGroup,
      onChanged: (value) {
        selectedGroup = value;
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a user group';
        }
        return null;
      },
    );
  }

  Widget _buildAddUserButton(BuildContext context) {
    return FilledButton(
      child: Text("Add User"),
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          Navigator.pop(
            context,
            AddUserResult(email: _emailController.text, group: selectedGroup!),
          );
        }
      },
    );
  }
}

class AddUserResult {
  final String email;
  final UserGroup group;

  AddUserResult({required this.email, required this.group});
}
