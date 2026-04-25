import 'dart:collection';

import 'package:animal_room_task_manager/theme_data.dart';
import 'package:flutter/material.dart';

import 'user_repository.dart';

class AdminTransferPage extends StatefulWidget {
  final UnmodifiableListView<User> users;

  const AdminTransferPage(this.users, {super.key});

  @override
  State<AdminTransferPage> createState() => _AdminTransferPageState();
}

class _AdminTransferPageState extends State<AdminTransferPage> {
  User? selectedUser;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Admin Transfer",
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            constrainToPhoneWidth(_buildDropdownForUserList()),
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
      ),
    );
  }

  Widget _buildDropdownForUserList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        largeTitleText(context, "New Admin"),
        padding8,
        constrainTextBoxWidth(
          DropdownButtonFormField<User>(
            initialValue: selectedUser,
            items: widget.users
                .where((u) => u.group != UserGroup.admin)
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
    if (selectedUser == null || selectedUser!.group != UserGroup.admin) {
      return "Please select a new admin";
    }
    return null;
  }

  Widget _buildConfirmButton(BuildContext context) {
    return FilledButton(
      child: const Text("Confirm"),
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
