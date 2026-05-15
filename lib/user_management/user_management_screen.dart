import 'package:animal_room_task_manager/theme_data.dart';
import 'package:animal_room_task_manager/user_management/user_list_model.dart';
import 'package:animal_room_task_manager/user_management/user_repository.dart';
import 'package:flutter/material.dart';

import 'edit_user_page.dart';
import 'admin_transfer_page.dart';

class UserManagementScreen extends StatelessWidget {
  final UserListModel _model;

  const UserManagementScreen({super.key, required UserListModel userListModel})
    : _model = userListModel;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Manage Users",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          padding8,
          _buildAdminRow(context),
          padding8,
          _buildUserListWidget(),
          padding8,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [cancelButton(), _buildAddNewUserButton(context)],
          ),
          padding8,
        ],
      ),
    );
  }

  Widget _buildAdminRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ListenableBuilder(
          listenable: _model.usersNotifier,
          builder: (context, _) => mediumTitleText(
            context,
            "Current Admin: \n"
            "    Email: ${_model.admin.email}\n"
            "    Role: ${userGroupToString(_model.admin.group)}",
          ),
        ),
        _buildAdminTransferButton(),
      ],
    );
  }

  Widget _buildAdminTransferButton() {
    return FilledButton(
      child: Text("Change Admin"),
      onPressed: () async {
        final User? result = await navigate(
          AdminTransferPage(userListModel: _model),
        );
        if (result != null) {
          _model.changeAdmin(result);
        }
      },
    );
  }

  Widget _buildUserListWidget() {
    return constrainToPhoneWidth(
      ListenableBuilder(
        listenable: _model.usersNotifier,
        builder: (context, _) => ListView(
          shrinkWrap: true,
          children: _model.users
              .where((user) => user.group != UserGroup.admin)
              .map((user) => _buildUserListTile(context, user))
              .toList(),
        ),
      ),
    );
  }

  ListTile _buildUserListTile(BuildContext context, User user) {
    return ListTile(
      title: mediumTitleText(
        context,
        "Email: ${user.email}\nRole:  ${userGroupToString(user.group)}",
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEditIconButton(user),
          _buildDeleteIconButton(context, user),
        ],
      ),
    );
  }

  IconButton _buildEditIconButton(User user) {
    return IconButton(
      icon: Icon(Icons.edit),
      onPressed: () async {
        final User? editedUser = await navigate(
          EditUserPage(title: "Edit User", user: user),
        );
        if (editedUser != null) {
          _model.updateUser(editedUser);
        }
      },
    );
  }

  IconButton _buildDeleteIconButton(BuildContext context, User user) {
    return IconButton(
      icon: Icon(Icons.delete),
      onPressed: () async {
        await showDialog<bool>(
          context: context,
          builder: (context) => _buildDeleteUserConfirmationDialog(user),
        ).then((result) {
          if (result == true) {
            _model.removeUser(user);
          }
        });
      },
    );
  }

  AlertDialog _buildDeleteUserConfirmationDialog(User user) {
    return AlertDialog(
      title: Text('Confirm User Deletion'),
      content: Text('Are you sure you want to delete $user?'),
      actions: [
        FilledButton(
          onPressed: () => unNavigate(result: false),
          child: Text('No'),
        ),
        FilledButton(
          onPressed: () => unNavigate(result: true),
          child: Text('Yes'),
        ),
      ],
    );
  }

  Widget _buildAddNewUserButton(BuildContext context) {
    return FilledButton(
      onPressed: () async {
        final User? user = await navigate(
          EditUserPage(title: "Add New User", user: null),
        );
        if (user != null) {
          _model.addEmailToWhitelist(
            User(email: user.email, group: user.group, uid: null),
          );
        }
      },
      child: Text("Add New User"),
    );
  }
}
