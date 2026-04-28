import 'package:animal_room_task_manager/building_management/building_management_model.dart';
import 'package:animal_room_task_manager/building_management/building_management_screen.dart';
import 'package:animal_room_task_manager/building_management/building_repository.dart';
import 'package:animal_room_task_manager/lab_management/lab_management_model.dart';
import 'package:animal_room_task_manager/lab_management/lab_management_screen.dart';
import 'package:animal_room_task_manager/lab_management/lab_repository.dart';
import 'package:animal_room_task_manager/login_screen/login_screen.dart';
import 'package:animal_room_task_manager/login_screen/login_use_case.dart';
import 'package:animal_room_task_manager/room_check/record_repository.dart';
import 'package:animal_room_task_manager/room_check/room_check_repository.dart';
import 'package:animal_room_task_manager/scheduler/scheduling_model.dart';
import 'package:animal_room_task_manager/scheduler/scheduling_screen.dart';
import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_management_model.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_management_screen.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:animal_room_task_manager/user_management/user_list_model.dart';
import 'package:animal_room_task_manager/user_management/user_management_screen.dart';
import 'package:animal_room_task_manager/user_management/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'facility_management/facility_management_model.dart';
import 'facility_management/facility_management_screen.dart';
import 'facility_management/facility_repository.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  Database database = await Database.create();
  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: database),
        Provider.value(value: BuildingRepository(database: database)),
        Provider.value(value: LabRepository(database: database)),
        Provider.value(value: FacilityRepository(database: database)),
        Provider.value(value: RoomCheckRepository(database: database)),
        Provider.value(value: TaskListRepository(database: database)),
        Provider.value(value: UserRepository(database: database)),
        ChangeNotifierProvider(
          create: (context) {
            var userRepository = context.read<UserRepository>();
            return LoginUseCase(userRepository: userRepository);
          },
        ),
        ChangeNotifierProvider(
          create: (context) => RecordRepository(database: database),
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
      home: loginUseCase.loggedInUser == null
          ? LoginScreen(loginUseCase: loginUseCase)
          : Builder(
              builder: (context) {
                BuildingRepository buildingRepository = context.read();
                LabRepository labRepository = context.read();
                FacilityRepository facilityRepository = context.read();
                RecordRepository recordRepository = context.read();
                RoomCheckRepository roomCheckRepository = context.read();
                TaskListRepository taskListRepository = context.read();
                UserRepository userRepository = context.read();

                return TaskListManagementScreen(
                  model: TaskListManagementModel(
                    taskListRepository: taskListRepository,
                  ),
                );

                // return BuildingManagementScreen(
                //   model: BuildingManagementModel(
                //     buildingRepository: buildingRepository,
                //   ),
                // );

                // return LabManagementScreen(
                //   model: LabManagementModel(labRepository: labRepository),
                // );

                // return FacilityManagementScreen(
                //   model: FacilityManagementModel(facilityRepository: facilityRepository),
                // );

                // return UserManagementScreen(
                //   userListModel: UserListModel(userRepository: userRepository),
                // );

                // return SchedulingScreen(
                //   schedulingModel: SchedulingModel(
                //     recordRepository: recordRepository,
                //     roomCheckRepository: roomCheckRepository,
                //     taskListRepository: taskListRepository,
                //   ),
                // );
              },
            ),
    );
  }
}
