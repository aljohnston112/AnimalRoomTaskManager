import 'package:animal_room_task_manager/theme_data.dart';
import 'package:flutter/material.dart';

String? validateEmail(String? value) {
  // TODO turn this back on
  // if (value == null || !RegExp(r'^.+@uwosh\.edu$').hasMatch(value)) {
  //   return 'Email must include @uwosh.edu';
  // }
  return null;
}

Widget buildEmailTextFormField(TextEditingController? controller) {
  return constrainToPhoneWidth(
    TextFormField(
      controller: controller,
      decoration: const InputDecoration(hintText: "Email"),
      autovalidateMode: AutovalidateMode.onUnfocus,
      validator: validateEmail,
    ),
  );
}
