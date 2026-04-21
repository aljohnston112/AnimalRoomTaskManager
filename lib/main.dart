import 'package:animal_room_task_manager/facility_repository.dart';
import 'package:animal_room_task_manager/login_screen/login_screen.dart';
import 'package:animal_room_task_manager/login_screen/login_use_case.dart';
import 'package:animal_room_task_manager/room_check/record_repository.dart';
import 'package:animal_room_task_manager/room_check/room_check_repository.dart';
import 'package:animal_room_task_manager/scheduler/scheduling_model.dart';
import 'package:animal_room_task_manager/scheduler/scheduling_screen.dart';
import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:animal_room_task_manager/user_management/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  Database database = await Database.create();
  final roomCheckRepository = RoomCheckRepository(database: database);
  //await roomCheckRepository.loadRoomChecks();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: database),
        ChangeNotifierProvider(
          create: (context) => FacilityRepository(database: database),
        ),
        ChangeNotifierProvider(
          create: (context) => UserRepository(database: database),
        ),
        ChangeNotifierProxyProvider<UserRepository, LoginUseCase>(
          create: (context) =>
              LoginUseCase(userRepository: context.read<UserRepository>()),
          update: (context, userRepository, previousLoginUseCase) {
            return previousLoginUseCase ??
                LoginUseCase(userRepository: userRepository);
          },
        ),
        ChangeNotifierProvider(create: (context) => RecordRepository()),
        Provider.value(value: roomCheckRepository),
        ChangeNotifierProvider(
          create: (context) => TaskListRepository(database: database),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final String appName = 'ACF Chex';
    final loginUseCase = context.watch<LoginUseCase>();
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
      themeMode: ThemeMode.light,
      home:
          // UserManagementScreen(
          //   userListModel: UserListModel(
          //       userRepository: context.read<UserRepository>()),
          // ),
          loginUseCase.loggedInUser == null
          ? LoginScreen(loginUseCase: loginUseCase)
          : Builder(
              builder: (context) {
                RecordRepository recordRepository = context
                    .read<RecordRepository>();
                RoomCheckRepository roomCheckRepository = context
                    .read<RoomCheckRepository>();
                TaskListRepository taskListRepository = context
                    .read<TaskListRepository>();
                return SchedulingScreen(
                  schedulingModel: SchedulingModel(
                    recordRepository: recordRepository,
                    roomCheckRepository: roomCheckRepository,
                    taskListRepository: taskListRepository,
                  ),
                );
              },
            ),
    );
  }
}
