import 'dart:collection';

import 'package:animal_room_task_manager/user_list_model.dart';
import 'package:animal_room_task_manager/user_repository.dart';
import 'package:flutter/material.dart';

import 'add_user_page.dart';
import 'admin_transfer_page.dart';

class UserManagementScreen extends StatelessWidget {
  final UserListModel userListModel;

  const UserManagementScreen({super.key, required this.userListModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: userListModel,
      builder: (context, _) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AdminRow(userListModel: userListModel),
            UserList(userListModel: userListModel),
            _buildAddNewUserButton(context),
          ],
        );
      },
    );
  }

  ElevatedButton _buildAddNewUserButton(BuildContext context) {
    return ElevatedButton(
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

class AdminRow extends StatelessWidget{

  final UserListModel userListModel;

  const AdminRow({super.key, required this.userListModel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text("Admin: ${userListModel.admin}"),
        _buildAdminTransferButton(context),
      ],
    );
  }

  ElevatedButton _buildAdminTransferButton(BuildContext context) {
    return ElevatedButton(
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
      child: Text("Change Admin"),
    );
  }

}

class UserList extends StatelessWidget{

  final UserListModel userListModel;

  const UserList({super.key, required this.userListModel});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView(
        children: userListModel.users
            .where((user) => user.group != UserGroup.admin)
            .map((user) => _buildUserListTile(context, user))
            .toList(),
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
        showDialog<bool>(
          context: context,
          builder: (context) =>
              buildDeleteUserConfirmationDialog(user, context),
        ).then((result) {
          if (result == true) {
            userListModel.removeUser(user);
          }
        });
      },
    );
  }

  AlertDialog buildDeleteUserConfirmationDialog(
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