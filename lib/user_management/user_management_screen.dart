import 'package:animal_room_task_manager/theme_data.dart';
import 'package:animal_room_task_manager/user_management/user_list_model.dart';
import 'package:animal_room_task_manager/user_management/user_repository.dart';
import 'package:flutter/material.dart';

import 'add_user_page.dart';
import 'admin_transfer_page.dart';

class UserManagementScreen extends StatelessWidget {
  final UserListModel _userListModel;

  const UserManagementScreen({super.key, required UserListModel userListModel})
    : _userListModel = userListModel;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Manage Users",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          padding8,
          AdminRow(userListModel: _userListModel),
          padding8,
          UserListWidget(userListModel: _userListModel),
          padding8,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              _buildAddNewUserButton(context, _userListModel),
            ],
          ),
          padding8,
        ],
      ),
    );
  }

  Widget _buildAddNewUserButton(
    BuildContext context,
    UserListModel userListModel,
  ) {
    return FilledButton(
      onPressed: () async {
        final AddUserResult? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddNewUserPage("Add New User", null, null),
          ),
        );
        if (result != null) {
          userListModel.addEmailToWhitelist(
            User(email: result.email, group: result.group, uid: null),
          );
        }
      },
      child: Text("Add New User"),
    );
  }
}

class AdminRow extends StatelessWidget {
  final UserListModel userListModel;

  const AdminRow({super.key, required this.userListModel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ListenableBuilder(
          listenable: userListModel,
          builder: (context, _) {
            return mediumTitleText(
              context,
              "Current Admin: \n    Email: ${userListModel.admin.email}\n    Role: ${userGroupToString(userListModel.admin.group)}",
            );
          },
        ),
        _buildAdminTransferButton(context),
      ],
    );
  }

  Widget _buildAdminTransferButton(BuildContext context) {
    return FilledButton(
      child: Text("Change Admin"),
      onPressed: () async {
        final User? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminTransferPage(userListModel.users),
          ),
        );
        if (result != null) {
          userListModel.changeAdmin(result);
        }
      },
    );
  }
}

class UserListWidget extends StatelessWidget {
  final UserListModel userListModel;

  const UserListWidget({super.key, required this.userListModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: userListModel,
      builder: (context, _) {
        return constrainToPhoneWidth(
          ListView(
            shrinkWrap: true,
            children: userListModel.users
                .where((user) => user.group != UserGroup.admin)
                .map((user) => _buildUserListTile(context, user))
                .toList(),
          ),
        );
      },
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
          _buildEditIconButton(context, user),
          _buildDeleteIconButton(context, user),
        ],
      ),
    );
  }

  IconButton _buildEditIconButton(BuildContext context, User user) {
    return IconButton(
      icon: Icon(Icons.edit),
      onPressed: () async {
        final AddUserResult? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddNewUserPage("Edit User", user.email, user.group),
          ),
        );
        if (result != null) {
          userListModel.updateUser(
            User(email: result.email, group: result.group, uid: user.uid),
          );
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
          builder: (context) =>
              _buildDeleteUserConfirmationDialog(user, context),
        ).then((result) {
          if (result == true) {
            userListModel.removeUser(user);
          }
        });
      },
    );
  }

  AlertDialog _buildDeleteUserConfirmationDialog(
    User user,
    BuildContext context,
  ) {
    return AlertDialog(
      title: Text('Confirm User Deletion'),
      content: Text('Are you sure you want to delete $user?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Yes'),
        ),
      ],
    );
  }
}
