import 'package:animal_room_task_manager/room_check/record_repository.dart';
import 'package:animal_room_task_manager/scheduler/room_check_list.dart';
import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:animal_room_task_manager/user_management/user_repository.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Database database = await Database.create();
  runApp(
    MyApp(
      userRepository: UserRepository(),
      taskListRepository: TaskListRepository(),
      recordRepository: RecordRepository(),
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
    final String appName = 'ACF Chex';
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: '$appName Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.yellow,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.yellow,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home:
          // UserManagementScreen(
          //   userListModel: UserListModel(userRepository: userRepository),
          // )
          // RoomCheckScreen(
          //   roomCheckModel: RoomCheckModel(
          //     taskList: TaskListRepository.dailyTasks[3],
          //     recordRepository: recordRepository,
          //   ),
          // ),
          RoomCheckListScreen(recordRepository: recordRepository),
    );
  }
}
