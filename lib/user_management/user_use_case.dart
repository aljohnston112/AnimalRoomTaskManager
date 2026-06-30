import 'package:animal_room_task_manager/theme_data.dart';
import 'package:flutter/material.dart';

String? validateEmail(String? value) {
  if (value == null || !RegExp(r'^.+@uwosh\.edu$').hasMatch(value)) {
    return 'Email must include @uwosh.edu';
  }
  return null;
}

Widget buildEmailTextFormField(
  BuildContext context,
  TextEditingController? controller,
) {
  return constrainToPhoneWidth(
    buildTextFormField(
      controller: controller,
      autofillHints: const [AutofillHints.username],
      hintText: "Email",
      validator: validateEmail,
      context: context,
    ),
  );
}
