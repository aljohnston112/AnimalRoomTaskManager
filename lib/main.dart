import 'package:animal_room_task_manager/postgresql_client/Database.dart';
import 'package:animal_room_task_manager/room_check/record_repository.dart';
import 'package:animal_room_task_manager/room_check/room_check_model.dart';
import 'package:animal_room_task_manager/room_check/room_check_screen.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:animal_room_task_manager/user_management/user_list_model.dart';
import 'package:animal_room_task_manager/user_management/user_management_screen.dart';
import 'package:animal_room_task_manager/user_management/user_repository.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  final database = await Database.create();
  var userRepository = UserRepository();
  var taskListRepository = TaskListRepository();
  var recordRepository = RecordRepository();
  runApp(
    MyApp(
      userRepository: userRepository,
      taskListRepository: taskListRepository,
      recordRepository: recordRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  final UserRepository userRepository;
  final TaskListRepository taskListRepository;
  final RecordRepository recordRepository;

  const MyApp({
    super.key,
    required this.userRepository,
    required this.taskListRepository,
    required this.recordRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.green)),
      home: Scaffold(
        appBar: AppBar(),
        body:
            // UserManagementScreen(
            //   userListModel: UserListModel(userRepository: userRepository),
            // )
            RoomCheckScreen(
              roomCheckModel: RoomCheckModel(
                taskList: taskListRepository.dailyTasks[3],
                recordRepository: recordRepository,
              ),
            ),
      ),
    );
  }
}
