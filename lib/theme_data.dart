import 'package:flutter/material.dart';

const double widePhoneWidth = 450;
const double maxTextFieldWidth = 320;

const EdgeInsets insets8 = EdgeInsets.all(8);
const Padding padding8 = Padding(padding: EdgeInsetsGeometry.all(8));
const Padding padding16 = Padding(padding: EdgeInsetsGeometry.all(16));

Text largeTitleText(BuildContext context, String text) =>
    Text(text, style: Theme.of(context).textTheme.titleLarge);

Text mediumTitleText(BuildContext context, String text) =>
    Text(text, style: Theme.of(context).textTheme.titleMedium);

Text smallTitleText(BuildContext context, String text) =>
    Text(text, style: Theme.of(context).textTheme.titleSmall);

Scaffold buildScaffold({required String title, required Widget child}) {
  return Scaffold(
    appBar: AppBar(title: Text(title), automaticallyImplyLeading: false),
    body: SafeArea(child: child),
  );
}

InputDecoration buildInputDecoration(String hint) {
  return InputDecoration(
    floatingLabelBehavior: FloatingLabelBehavior.always,
    border: OutlineInputBorder(),
    filled: true,
    labelText: hint,
  );
}

void showSnackBar(BuildContext context, String message) {
  final snackBar = SnackBar(
    content: Text(message),
    behavior: SnackBarBehavior.floating,
    showCloseIcon: true,
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

ConstrainedBox constrainToPhoneWidth(Widget child) {
  return ConstrainedBox(
    // To prevent the list from taking up the full width of a wide screen
    constraints: const BoxConstraints(maxWidth: widePhoneWidth),
    child: child,
  );
}

ConstrainedBox constrainTextBoxWidth(Widget child) {
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: maxTextFieldWidth),
    child: child,
  );
}
