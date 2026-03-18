import 'dart:collection';

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
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Transfer")),
      body: Column(
        children: [_buildDropdownForUserList(), _buildConfirmButton(context)],
      ),
    );
  }

  DropdownButtonFormField<User> _buildDropdownForUserList() {
    return DropdownButtonFormField<User>(
      initialValue: selectedUser,
      items: widget.users
          .where((u) => u.group != UserGroup.admin)
          .map((u) => DropdownMenuItem(value: u, child: Text(u.toString())))
          .toList(),
      onChanged: (value) {
        setState(() {
          selectedUser = value;
        });
      },
      validator: _validateSelectedUser,
    );
  }

  String? _validateSelectedUser(User? _) {
    if (selectedUser == null || selectedUser!.group != UserGroup.admin) {
      return "Please select a new admin";
    }
    return null;
  }

  ElevatedButton _buildConfirmButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.pop(context, selectedUser),
      child: const Text("Confirm"),
    );
  }
}
