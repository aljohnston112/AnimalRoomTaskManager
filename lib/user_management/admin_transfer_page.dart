import 'package:animal_room_task_manager/theme_data.dart';
import 'package:animal_room_task_manager/user_management/user_list_model.dart';
import 'package:flutter/material.dart';

import 'user_repository.dart';

class AdminTransferPage extends StatefulWidget {
  final UserListModel _model;

  const AdminTransferPage({super.key, required UserListModel userListModel})
    : _model = userListModel;

  @override
  State<AdminTransferPage> createState() => _AdminTransferPageState();
}

class _AdminTransferPageState extends State<AdminTransferPage> {
  User? _selectedUser;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Admin Transfer",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          constrainToPhoneWidth(_buildDropdownForUserList()),
          padding8,
          constrainToPhoneWidth(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [cancelButton(), _buildSubmitButton()],
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
        largeTitleText(context, "New Admin"),
        padding8,
        constrainTextBoxWidth(
          ListenableBuilder(
            listenable: widget._model.usersNotifier,
            builder: (context, _) => DropdownButtonFormField<User>(
              initialValue: _selectedUser,
              items: widget._model.users
                  .where((user) => user.group != UserGroup.admin)
                  .map(
                    (user) =>
                        DropdownMenuItem(value: user, child: Text(user.email)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedUser = value;
                });
              },
              validator: _validateSelectedUser,
            ),
          ),
        ),
      ],
    );
  }

  String? _validateSelectedUser(User? _) {
    if (_selectedUser == null || _selectedUser!.group != UserGroup.admin) {
      return "Please select a new admin";
    }
    return null;
  }

  Widget _buildSubmitButton() {
    return FilledButton(
      child: const Text("Submit"),
      onPressed: () => unNavigate(result: _selectedUser),
    );
  }
}
