import 'package:animal_room_task_manager/login_screen/login_use_case.dart';
import 'package:animal_room_task_manager/user_use_case.dart';
import 'package:flutter/material.dart';

import '../theme_data.dart';

/// A login screen
class LoginScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final LoginUseCase _loginUseCase;

  LoginScreen({super.key, required loginModel}) : _loginUseCase = loginModel {
    _emailController.text = "test@uwosh.edu";
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: buildScaffold(
        title: 'Login',
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              buildEmailTextFormField(_emailController),
              padding8,
              _buildLoginButton(context),
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildLoginButton(BuildContext context) {
    return FilledButton(
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          _loginUseCase.login(_emailController.text);
        }
      },
      child: Text("Log in"),
    );
  }
}
