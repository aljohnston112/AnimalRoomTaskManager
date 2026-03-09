import 'package:animal_room_task_manager/postgresql_client/Database.dart';
import 'package:animal_room_task_manager/user_list_model.dart';
import 'package:animal_room_task_manager/user_management_screen.dart';
import 'package:animal_room_task_manager/user_repository.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  final database = await Database.create();
  var userRepository = UserRepository();
  runApp(MyApp(userRepository));
}

class MyApp extends StatelessWidget {
  final UserRepository userRepository;

  const MyApp(this.userRepository, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.green)),
      home: Scaffold(
        appBar: AppBar(),
        body: UserManagementScreen(
            userListModel: UserListModel(userRepository: userRepository)
        ),
      ),
    );
  }
}
