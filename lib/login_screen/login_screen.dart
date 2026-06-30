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
        context: context,
        child: center(
          constrainToPhoneWidth(
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                constrainTextBoxWidth(
                  Column(
                    children: [
                      buildEmailTextFormField(context, _emailController),
                      padding8,
                      _buildPasswordFormField(context, _passwordController),
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

  Widget _buildPasswordFormField(
    BuildContext context,
    TextEditingController passwordController,
  ) {
    return constrainToPhoneWidth(
      buildTextFormField(
        controller: passwordController,
        autofillHints: const [AutofillHints.password],
        hintText: "Password",
        obscureText: true,
        validator: validatePassword,
        context: context,
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
}
