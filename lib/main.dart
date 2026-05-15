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
import 'package:animal_room_task_manager/species_management/species_management_model.dart';
import 'package:animal_room_task_manager/species_management/species_management_screen.dart';
import 'package:animal_room_task_manager/species_management/species_repository.dart';
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

// TODO
// TASK_LIST.2.0.2
// The admin shall be able to add a notification trigger comprised of
// a minimum and maximum value for the quantitative variable

// TASK_LIST.8
// The admin shall be able to delete any task list not linked to any room

// TASK_LIST.9
// The admin shall be able to mark any task list assigned to a room as idle

// TASK_LIST.9.1
// Idle task lists shall stay assigned to the room they were assigned to
// when marked idle

// TASK_LIST.9.2
// Idle task lists will only be idle for the rooms they are marked idle for

// ROOM_CHECK.1
// If a task contains the recording of a quantitative variable
// with notification triggers, the system shall inform the user,
// principal investigators, and the admin if any of those recorded values
// are out of the specified range and submitted

// ROOM_CHECK.6.0
// If a comment is recorded in a walkthrough, the admin
// and principal investigators shall be notified of the comment's content

// ROOM_CHECK.6.0.1
// The notification shall include the lab, room, and task
// that the comment was recorded for

// ROOM_CHECK.7
// When all the room checks for a lab are done, the admin
// and principal investigators shall get a notification

// ROOM_CHECK.7.0
// The notification shall include the lab whose room checks are done

// CENSUS.1.2
// A recorded census shall be retrievable for at least seven years
// by the admin and principal investigators

// LAB.1.0
// The admin shall be able to change the color assigned to a lab

// LAB.2
// The lab shall keep a list of users who belong to the lab

// LAB.2.0
// A user may belong to multiple labs

// SCHEDULE.2
// The admin and principal investigators shall be able to assign any user
// to any room check not in progress

// SCHEDULE.2.0
// If the room check has a user assigned, the new assignment will remove
// that user before assigning the new one

// SCHEDULE.3
// Room check time slots shall have a color that indicates the lab association

// SCHEDULE.4
// The system shall make apparent if a room check is in progress

// SCHEDULE.5
// A user shall have the ability to assign,
// users they have permission to assign to room checks to,
// to a room on a specific set of weekdays over a time frame
// consisting of an interval over two future dates

// TODO clear snackbars when navigating; and switch to navigation functions in theme_data

Future<void> main() async {
  Database database = await Database.create();
  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: database),
        Provider.value(value: SpeciesRepository(database: database)),
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
            SpeciesManagementScreen(
              model: SpeciesManagementModel(speciesRepository: context.read()),
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
