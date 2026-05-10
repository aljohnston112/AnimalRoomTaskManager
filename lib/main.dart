import 'package:animal_room_task_manager/animal_management/animal_management_model.dart';
import 'package:animal_room_task_manager/animal_management/animal_management_screen.dart';
import 'package:animal_room_task_manager/animal_management/animal_repository.dart';
import 'package:animal_room_task_manager/building_management/building_management_model.dart';
import 'package:animal_room_task_manager/building_management/building_management_screen.dart';
import 'package:animal_room_task_manager/building_management/building_repository.dart';
import 'package:animal_room_task_manager/census/census_model.dart';
import 'package:animal_room_task_manager/census/census_repository.dart';
import 'package:animal_room_task_manager/census/census_screen.dart';
import 'package:animal_room_task_manager/facility_management/facility_management_model.dart';
import 'package:animal_room_task_manager/facility_management/facility_management_screen.dart';
import 'package:animal_room_task_manager/lab_management/lab_management_model.dart';
import 'package:animal_room_task_manager/lab_management/lab_management_screen.dart';
import 'package:animal_room_task_manager/lab_management/lab_repository.dart';
import 'package:animal_room_task_manager/login_screen/login_screen.dart';
import 'package:animal_room_task_manager/login_screen/login_use_case.dart';
import 'package:animal_room_task_manager/query/query_repository.dart';
import 'package:animal_room_task_manager/query/query_screen.dart';
import 'package:animal_room_task_manager/room_check/record_repository.dart';
import 'package:animal_room_task_manager/room_check/room_check_repository.dart';
import 'package:animal_room_task_manager/room_management/room_management_model.dart';
import 'package:animal_room_task_manager/room_management/room_management_screen.dart';
import 'package:animal_room_task_manager/room_management/room_repository.dart';
import 'package:animal_room_task_manager/scheduler/scheduling_home_screen.dart';
import 'package:animal_room_task_manager/scheduler/scheduling_model.dart';
import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_management_model.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_management_screen.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:animal_room_task_manager/theme_data.dart';
import 'package:animal_room_task_manager/user_management/user_list_model.dart';
import 'package:animal_room_task_manager/user_management/user_management_screen.dart';
import 'package:animal_room_task_manager/user_management/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'facility_management/facility_repository.dart';

// TODO clear snackbars when navigating; and switch to navigation functions in theme_data

Future<void> main() async {
  Database database = await Database.create();
  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: database),
        Provider.value(value: AnimalRepository(database: database)),
        Provider.value(value: BuildingRepository(database: database)),
        Provider.value(value: CensusRepository(database: database)),
        Provider.value(value: LabRepository(database: database)),
        Provider.value(value: FacilityRepository(database: database)),
        Provider.value(value: QueryRepository(database: database)),
        Provider.value(value: RecordRepository(database: database)),
        Provider.value(value: RoomRepository(database: database)),
        Provider.value(value: RoomCheckRepository(database: database)),
        Provider.value(value: TaskListRepository(database: database)),
        Provider.value(value: UserRepository(database: database)),
        ChangeNotifierProvider(
          create: (context) {
            var userRepository = context.read<UserRepository>();
            return LoginUseCase(userRepository: userRepository);
          },
        ),
      ],
      child: AnimalCareFacilityCheckApp(),
    ),
  );
}

class AnimalCareFacilityCheckApp extends StatelessWidget {
  const AnimalCareFacilityCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      home: Builder(
        builder: (context) {
          if (loginUseCase.isInitializing) {
            return const Center(child: CircularProgressIndicator());
          }
          return loginUseCase.loggedInUser == null
              ? LoginScreen(loginUseCase: loginUseCase)
              : _buildHomeScreen(context, loginUseCase);
        },
      ),
    );
  }

  Scaffold _buildHomeScreen(BuildContext context, LoginUseCase loginUseCase) {
    return buildScaffold(
      title: appName,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (loginUseCase.loggedInUser?.group == UserGroup.admin)
            ..._buildAdminButtons(context),
          padding8,
          ..._buildAllUserButtons(context),
        ],
      ),
    );
  }

  List<Widget> _buildAdminButtons(BuildContext context) {
    return [
      FilledButton(
        onPressed: () async {
          await navigate(
            AnimalManagementScreen(
              model: AnimalManagementModel(animalRepository: context.read()),
            ),
          );
        },
        child: Text("Species Editor"),
      ),
      padding8,
      FilledButton(
        onPressed: () async {
          await navigate(
            BuildingManagementScreen(
              model: BuildingManagementModel(
                buildingRepository: context.read(),
              ),
            ),
          );
        },
        child: Text("Building Editor"),
      ),
      padding8,
      FilledButton(
        onPressed: () async {
          await navigate(
            FacilityManagementScreen(
              model: FacilityManagementModel(
                facilityRepository: context.read(),
              ),
            ),
          );
        },
        child: Text("Facility Editor"),
      ),
      padding8,
      FilledButton(
        onPressed: () async {
          await navigate(
            LabManagementScreen(
              model: LabManagementModel(labRepository: context.read()),
            ),
          );
        },
        child: Text("Lab Editor"),
      ),
      padding8,
      FilledButton(
        onPressed: () async {
          await navigate(
            RoomManagementScreen(
              model: RoomManagementModel(
                roomRepository: context.read(),
                buildingRepository: context.read(),
                facilityRepository: context.read(),
                labRepository: context.read(),
                taskListRepository: context.read(),
              ),
            ),
          );
        },
        child: Text("Room Editor"),
      ),
      padding8,
      FilledButton(
        onPressed: () async {
          await navigate(
            TaskListManagementScreen(
              model: TaskListManagementModel(
                taskListRepository: context.read(),
              ),
            ),
          );
        },
        child: Text("Task List Editor"),
      ),
      padding8,
      FilledButton(
        onPressed: () async {
          await navigate(
            UserManagementScreen(
              userListModel: UserListModel(userRepository: context.read()),
            ),
          );
        },
        child: Text("User Editor"),
      ),
      padding8,
      FilledButton(
        onPressed: () async {
          await navigate(QueryScreen());
        },
        child: Text("Query"),
      ),
    ];
  }

  List<Widget> _buildAllUserButtons(BuildContext context) {
    return [
      FilledButton(
        onPressed: () async {
          await navigate(
            CensusEntryScreen(
              model: CensusEntryModel(
                animalRepository: context.read(),
                roomRepository: context.read(),
                roomsWithCensuses: {},
              ),
              isFirstEntry: true,
              censusToEdit: null,
            ),
            tag: 'census',
          );
        },
        child: Text("Record a Census"),
      ),
      padding8,
      FilledButton(
        onPressed: () async {
          await navigate(
            SchedulingHomeScreen(
              schedulingModel: SchedulingModel(
                recordRepository: context.read(),
                roomCheckRepository: context.read(),
                taskListRepository: context.read(),
                userRepository: context.read(),
              ),
            ),
          );
        },
        child: Text("Scheduler and Room Checks"),
      ),
    ];
  }
}
