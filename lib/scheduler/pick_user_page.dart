import 'dart:collection';

import 'package:flutter/material.dart';

import '../theme_data.dart';
import '../user_management/user_repository.dart';

class PickUserPage extends StatefulWidget {
  final UnmodifiableSetView<User> users;

  const PickUserPage(this.users, {super.key});

  @override
  State<PickUserPage> createState() => _PickUserPageState();
}

class _PickUserPageState extends State<PickUserPage> {
  User? selectedUser;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Assign Room Check To",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          constrainToPhoneWidth(_buildDropdownForUserList()),
          padding8,
          constrainToPhoneWidth(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCancelButton(context),
                _buildConfirmButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownForUserList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        largeTitleText(context, "Assign To"),
        padding8,
        constrainTextBoxWidth(
          DropdownButtonFormField<User>(
            initialValue: selectedUser,
            items: widget.users
                .map((u) => DropdownMenuItem(value: u, child: Text(u.email)))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedUser = value;
              });
            },
            validator: _validateSelectedUser,
          ),
        ),
      ],
    );
  }

  String? _validateSelectedUser(User? _) {
    if (selectedUser == null) {
      return "Please select a user";
    }
    return null;
  }

  Widget _buildConfirmButton(BuildContext context) {
    return FilledButton(
      child: const Text("Assign"),
      onPressed: () => Navigator.pop(context, selectedUser),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return FilledButton(
      child: const Text("Cancel"),
      onPressed: () => Navigator.pop(context),
    );
  }
}
