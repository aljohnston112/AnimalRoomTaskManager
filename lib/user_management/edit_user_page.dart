import 'package:animal_room_task_manager/theme_data.dart';
import 'package:animal_room_task_manager/user_management/user_use_case.dart';
import 'package:flutter/material.dart';

import 'user_repository.dart';

class EditUserPage extends StatefulWidget {
  final User? user;
  final String title;

  const EditUserPage({super.key, required this.title, required this.user});

  @override
  State<StatefulWidget> createState() {
    return _EditUserPageState();
  }
}

class _EditUserPageState extends State<EditUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  UserGroup? _selectedUserGroup;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.user?.email ?? '';
    _selectedUserGroup = widget.user?.group;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: buildScaffold(
        title: widget.title,
        child: constrainTextBoxWidth(
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEmailTextField(context),
              _buildUserGroupDropdown(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [cancelButton(), _buildAddUserButton()],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailTextField(BuildContext context) {
    return constrainTextBoxWidth(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          mediumTitleText(context, "User Email"),
          TextFormField(
            controller: _emailController,
            enabled: widget.user == null,
            autovalidateMode: AutovalidateMode.onUnfocus,
            validator: validateEmail,
          ),
        ],
      ),
    );
  }

  Widget _buildUserGroupDropdown() {
    var dropDownItems = UserGroup.values
        .where((userGroup) {
          return userGroup != UserGroup.admin;
        })
        .map((userGroup) {
          return DropdownMenuItem(
            value: userGroup,
            child: Text(
              userGroupToString(userGroup),
              overflow: TextOverflow.ellipsis,
            ),
          );
        })
        .toList();
    return constrainTextBoxWidth(
      DropdownButtonFormField<UserGroup>(
        isExpanded: true,
        decoration: InputDecoration(hintText: widget.title),
        items: dropDownItems,
        initialValue: _selectedUserGroup,
        onChanged: (value) {
          _selectedUserGroup = value;
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a user group';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildAddUserButton() {
    return FilledButton(
      child: Text(widget.user == null ? "Add User" : "Update User"),
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          unNavigate(
            result: User(
              email: _emailController.text,
              group: _selectedUserGroup!,
              uid: widget.user?.uid,
            ),
          );
        }
      },
    );
  }
}
