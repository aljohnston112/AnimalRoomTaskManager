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
          AdminRow(userListModel: _userListModel),
          UserListWidget(userListModel: _userListModel),
          _buildAddNewUserButton(context, _userListModel),
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
          MaterialPageRoute(builder: (_) => AddNewUserPage(null, null)),
        );
        if (result != null) {
          userListModel.addUser(User(email: result.email, group: result.group));
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
            return Text("Admin: ${userListModel.admin}");
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
    return Expanded(
      child: ListenableBuilder(
        listenable: userListModel,
        builder: (context, _) {
          return ListView(
            children: userListModel.users
                .where((user) => user.group != UserGroup.admin)
                .map((user) => _buildUserListTile(context, user))
                .toList(),
          );
        },
      ),
    );
  }

  ListTile _buildUserListTile(BuildContext context, User user) {
    return ListTile(
      title: Center(child: Text(user.toString())),
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
            builder: (_) => AddNewUserPage(user.email, user.group),
          ),
        );
        if (result != null) {
          userListModel.updateUser(
            User(email: result.email, group: result.group),
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
