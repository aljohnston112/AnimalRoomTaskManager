import 'package:flutter/material.dart';

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
      child: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildEmailTextFormField(),
            _buildUserGroupDropdown(),
            _buildAddUserButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailTextFormField() {
    if (widget.user != null) {}
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(hintText: "Email"),
      validator: _validateEmail,
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || !RegExp(r'^.+@uwosh\.edu$').hasMatch(value)) {
      return 'Email must include @uwosh.edu';
    }
    return null;
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

  ElevatedButton _buildAddUserButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          Navigator.pop(
            context,
            AddUserResult(email: _emailController.text, group: selectedGroup!),
          );
        }
      },
      child: Text("Add User"),
    );
  }
}

class AddUserResult {
  final String email;
  final UserGroup group;

  AddUserResult({required this.email, required this.group});
}
