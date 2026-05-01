import 'package:animal_room_task_manager/login_screen/login_use_case.dart';
import 'package:animal_room_task_manager/user_management/user_use_case.dart';
import 'package:flutter/material.dart';

import '../theme_data.dart';

/// A login screen
class LoginScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final LoginUseCase _loginUseCase;

  LoginScreen({super.key, required loginUseCase})
    : _loginUseCase = loginUseCase;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: buildScaffold(
        title: 'Login',
        child: Center(
          child: constrainToPhoneWidth(
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      buildEmailTextFormField(_emailController),
                      padding8,
                      _buildPasswordFormField(_passwordController),
                    ],
                  ),
                ),
                padding8,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSignUpButton(context),
                    padding8,
                    _buildLoginButton(context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return FilledButton(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          bool loggedIn = await context.showLoading(
            _loginUseCase.login(
              _emailController.text,
              _passwordController.text,
            ),
          );
          if (!loggedIn) {
            if (context.mounted) {
              showSnackBar(context, 'Login failed');
            }
          }
        }
      },
      child: Text("Log in"),
    );
  }

  Widget _buildSignUpButton(BuildContext context) {
    return FilledButton(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          var signedUp = await context.showLoading(
            _loginUseCase.signup(
              _emailController.text,
              _passwordController.text,
            ),
          );
          if (!signedUp) {
            if (context.mounted) {
              showSnackBar(context, 'Sign up failed');
            }
          }
        }
      },
      child: Text("Sign Up"),
    );
  }

  Widget _buildPasswordFormField(TextEditingController passwordController) {
    return constrainToPhoneWidth(
      TextFormField(
        controller: passwordController,
        autofillHints: const [AutofillHints.password],
        decoration: const InputDecoration(hintText: "Password"),
        autovalidateMode: AutovalidateMode.onUnfocus,
        obscureText: true,
        validator: validatePassword,
      ),
    );
  }

  String? validatePassword(String? value) {
    if (value == null) {
      return "Please enter a password";
    }

    // (?=.*[a-zA-Z]) looks for the first letter
    // (?=.*\d) looks for the first digit
    // (?=.*[\W_]) looks for the first symbol (not a letter or number)
    // The triple lookahead consume no tokens
    // .{14,} consumes 14 characters
    final passwordPattern = RegExp(
      r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[\W_]).{14,}$',
    );
    if (!passwordPattern.hasMatch(value)) {
      return "Password must be at least 14 characters long, "
          "and contain a letter, number, and special character";
    }
    return null;
  }
}
