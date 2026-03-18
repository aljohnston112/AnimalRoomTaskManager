import 'package:flutter/material.dart';

const double widePhoneWidth = 450;
const double maxTextFieldWidth = 320;

const EdgeInsets insets8 = EdgeInsets.all(8.0);
const Padding padding8 = Padding(padding: EdgeInsetsGeometry.all(8));

TextStyle? largeTileTheme(BuildContext context) =>
    Theme.of(context).textTheme.titleLarge;

TextStyle? mediumTileTheme(BuildContext context) =>
    Theme.of(context).textTheme.titleMedium;

TextStyle? smallTileTheme(BuildContext context) =>
    Theme.of(context).textTheme.titleSmall;

InputDecoration buildInputDecoration(String hint) {
  return InputDecoration(
    floatingLabelBehavior: FloatingLabelBehavior.always,
    border: OutlineInputBorder(),
    filled: true,
    labelText: hint,
  );
}
