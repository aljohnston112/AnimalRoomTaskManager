import 'package:animal_room_task_manager/theme_data.dart';
import 'package:flutter/material.dart';

import '../user_use_case.dart';
import 'user_repository.dart';

class AddNewUserPage extends StatefulWidget {
  final String? user;
  final UserGroup? userGroup;

  const AddNewUserPage(this.user, this.userGroup, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _AddNewUserState();
  }
}

class _AddNewUserState extends State<AddNewUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  UserGroup? selectedGroup;

  _AddNewUserState();

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
        title: "Add User",
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            buildEmailTextFormField(_emailController),
            _buildUserGroupDropdown(),
            _buildAddUserButton(context),
          ],
        ),
      ),
    );
  }


  DropdownButtonFormField<UserGroup> _buildUserGroupDropdown() {
    return DropdownButtonFormField<UserGroup>(
      decoration: const InputDecoration(hintText: "User Group"),
      items: UserGroup.values
          .where((group) {
            return group != UserGroup.admin;
          })
          .map((group) {
            return DropdownMenuItem(value: group, child: Text(group.name));
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
