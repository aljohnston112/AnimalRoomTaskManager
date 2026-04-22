import 'package:animal_room_task_manager/login_screen/login_use_case.dart';
import 'package:animal_room_task_manager/scheduler/scheduling_model.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:animal_room_task_manager/theme_data.dart';
import 'package:animal_room_task_manager/user_management/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../room_check/room_check_model.dart';
import '../room_check/room_check_repository.dart';
import '../room_check/room_check_screen.dart';

class SchedulingScreen extends StatelessWidget {
  final SchedulingModel schedulingModel;

  const SchedulingScreen({super.key, required this.schedulingModel});

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Scheduler",
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDailySchedulingButton(context),
            _buildWeeklySchedulingButton(context),
            _buildMonthlySchedulingButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySchedulingButton(BuildContext context) {
    return FilledButton(
      child: Text("Daily"),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SchedulingScreenCards(
              taskFrequency: TaskFrequency.daily,
              schedulingModel: schedulingModel,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklySchedulingButton(BuildContext context) {
    return FilledButton(
      child: Text("Weekly"),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SchedulingScreenCards(
              taskFrequency: TaskFrequency.weekly,
              schedulingModel: schedulingModel,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlySchedulingButton(BuildContext context) {
    return FilledButton(
      child: Text("Monthly"),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SchedulingScreenCards(
              taskFrequency: TaskFrequency.monthly,
              schedulingModel: schedulingModel,
            ),
          ),
        );
      },
    );
  }
}

class SchedulingScreenCards extends StatelessWidget {
  final SchedulingModel schedulingModel;
  final TaskFrequency _taskFrequency;

  const SchedulingScreenCards({
    super.key,
    required TaskFrequency taskFrequency,
    required this.schedulingModel,
  }) : _taskFrequency = taskFrequency;

  @override
  Widget build(BuildContext context) {
    // Create the expanding cards that contain the room assignments
    final now = DateTime.now();
    return buildScaffold(
      title: switch (_taskFrequency) {
        TaskFrequency.daily => "Daily Tasks",
        TaskFrequency.weekly => "Weekly Tasks",
        TaskFrequency.monthly => "Monthly Tasks",
      },
      child: switch (_taskFrequency) {
        TaskFrequency.daily => _buildDailyTaskCardList(now, context),
        TaskFrequency.weekly => _buildWeeklyTaskCardList(now, context),
        TaskFrequency.monthly => _buildMonthlyTaskCardList(now, context),
      },
    );
  }

  SchedulerListView _buildDailyTaskCardList(
    DateTime now,
    BuildContext context,
  ) {
    final taskLists = Map.fromEntries(
      context.watch<TaskListRepository>().taskLists.entries.where(
        (e) => e.key.frequency == TaskFrequency.daily,
      ),
    );
    final List<String> uniqueBuildings = taskLists.keys
        .map((key) => key.buildingName)
        .toSet()
        .toList();
    uniqueBuildings.sort();

    Map<String, List<Widget>> cards = {};
    for (final building in uniqueBuildings) {
      cards[building] = [];
    }
    for (int i = 0; i < 32; i++) {
      final date = now.add(Duration(days: i));
      final month = date.month;
      final day = date.day;
      final year = date.year;
      var dateKey = "$month/$day/$year";
      for (final building in uniqueBuildings) {
        final taskInBuilding = Map.fromEntries(
          taskLists.entries
              .where((e) => e.key.buildingName == building)
              .toList(),
        );
        cards[building]!.add(
          _buildRoomAssignmentCards(context, taskInBuilding, dateKey, i == 0, (
            year: year,
            month: month,
            day: day,
          )),
        );
      }
    }
    return SchedulerListView(title: "Daily Scheduler", children: cards);
  }

  SchedulerListView _buildWeeklyTaskCardList(
    DateTime now,
    BuildContext context,
  ) {
    final taskLists = Map.fromEntries(
      context.watch<TaskListRepository>().taskLists.entries.where(
        (e) => e.key.frequency == TaskFrequency.weekly,
      ),
    );
    final List<String> uniqueBuildings = taskLists.keys
        .map((key) => key.buildingName)
        .toSet()
        .toList();
    uniqueBuildings.sort();

    Map<String, List<Widget>> cards = {};
    for (final building in uniqueBuildings) {
      cards[building] = [];
    }
    var previousSunday = now.subtract(Duration(days: now.weekday % 7));
    for (int i = 0; i < 4; i++) {
      previousSunday = previousSunday.add(Duration(days: i * 7));
      final previousMonth = previousSunday.month;
      final previousDay = previousSunday.day;
      final previousYear = previousSunday.year;

      final nextSunday = previousSunday.add(const Duration(days: 6));
      final nextMonth = nextSunday.month;
      final nextDay = nextSunday.day;
      final nextYear = nextSunday.year;

      var dateKey =
          "$previousMonth/$previousDay/$previousYear to "
          "$nextMonth/$nextDay/$nextYear";
      for (final building in uniqueBuildings) {
        final tasksInBuilding = Map.fromEntries(
          taskLists.entries
              .where((e) => e.key.buildingName == building)
              .toList(),
        );
        cards[building]!.add(
          _buildRoomAssignmentCards(context, tasksInBuilding, dateKey, i == 0, (
            year: nextYear,
            month: nextMonth,
            day: nextDay,
          )),
        );
      }
    }

    return SchedulerListView(title: "Weekly Scheduler", children: cards);
  }

  SchedulerListView _buildMonthlyTaskCardList(
    DateTime now,
    BuildContext context,
  ) {
    final taskLists = Map.fromEntries(
      context.watch<TaskListRepository>().taskLists.entries.where(
        (e) => e.key.frequency == TaskFrequency.monthly,
      ),
    );
    final List<String> uniqueBuildings = taskLists.keys
        .map((key) => key.buildingName)
        .toSet()
        .toList();
    uniqueBuildings.sort();

    Map<String, List<Widget>> cards = {};
    for (final building in uniqueBuildings) {
      cards[building] = [];
    }

    final String monthName = _getMonthName(now.month);
    final String dateKey = "$monthName ${now.year}";
    var isCurrentPeriod = true;

    for (final building in uniqueBuildings) {
      final tasksInBuilding = Map.fromEntries(
        taskLists.entries.where((e) => e.key.buildingName == building).toList(),
      );
      cards[building]!.add(
        _buildRoomAssignmentCards(
          context,
          tasksInBuilding,
          dateKey,
          isCurrentPeriod,
          (year: now.year, month: now.month, day: 1),
        ),
      );
    }
    return SchedulerListView(title: "Monthly Scheduler", children: cards);
  }

  String _getMonthName(int month) {
    const monthNames = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return monthNames[month - 1];
  }

  Widget _buildRoomAssignmentCards(
    BuildContext context,
    Map<TaskListKey, TaskList> taskLists,
    String dateString,
    bool isCurrentPeriod,
    RoomCheckDate date,
  ) {
    return Card(
      child: Padding(
        padding: insets8,
        child: ExpansionTile(
          key: PageStorageKey(dateString),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          title: mediumTitleText(context, dateString),
          children: _buildRoomAssignmentTiles(
            context,
            taskLists,
            isCurrentPeriod,
            date,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRoomAssignmentTiles(
    BuildContext context,
    Map<TaskListKey, TaskList> taskLists,
    bool isCurrentPeriod,
    RoomCheckDate date,
  ) {
    final List<TaskListKey> keys = taskLists.keys.toList();
    List<Widget> cards = [];
    for (var key in keys) {
      final roomTaskList = taskLists[key]!;
      final frequency = roomTaskList.frequency;
      cards.add(
        ListenableBuilder(
          listenable: schedulingModel,
          builder: (context, _) {
            var logInUseCase = context.read<LoginUseCase>();
            final TaskListState(:tasksDone, :doneBy) = schedulingModel
                .getTaskListState(roomTaskList, key.room, date);
            return Card(
              child: Padding(
                padding: insets8,
                child: Column(
                  children: [
                    mediumTitleText(context, key.room.name),
                    if (!tasksDone) ...[
                      padding8,
                      mediumTitleText(
                        context,
                        _getAssignedUserString(
                          schedulingModel.getUserAssignedToRoom(
                            key.buildingName,
                            date,
                            key.room,
                            frequency,
                          ),
                        ),
                      ),
                    ],
                    padding8,
                    if (tasksDone && doneBy != null) ...[
                      mediumTitleText(context, _getDoneByString(doneBy)),
                    ] else ...[
                      _buildAssignmentButton(
                        key.buildingName,
                        context,
                        date,
                        key.room,
                      ),
                    ],
                    if (isCurrentPeriod && !tasksDone) ...[
                      padding8,
                      FilledButton(
                        onPressed: () async {
                          // TODO assign room check if unassigned
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) {
                                return RoomCheckScreen(
                                  roomCheckModel: RoomCheckModel(
                                    buildingName: key.buildingName,
                                    room: key.room,
                                    taskList: roomTaskList,
                                    recordRepository: context.read(),
                                    roomCheckRepository: context.read(),
                                    date: date,
                                    loginUseCase: logInUseCase,
                                  ),
                                );
                              },
                            ),
                          );
                          // Reload after finishing, as there may be updates
                          schedulingModel.refreshData();
                        },
                        child: const Text("Start"),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
    return cards;
  }

  Widget _buildAssignmentButton(
    String buildingName,
    BuildContext context,
    RoomCheckDate date,
    Room room,
  ) {
    final loginUseCase = context.watch<LoginUseCase>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FilledButton(
          onPressed: () {
            schedulingModel.assignUserToRoomCheck(
              buildingName,
              date,
              room,
              loginUseCase.loggedInUser!,
              _taskFrequency,
            );
          },
          child: const Text("Assign to me"),
        ),
        padding8,
        FilledButton(onPressed: () {}, child: const Text("Assign to another")),
      ],
    );
  }

  String _getAssignedUserString(String? user) {
    if (user != null) {
      return "Assigned to $user";
    }
    return "Unassigned";
  }

  String _getDoneByString(User doneBy) {
    return "Done by ${doneBy.email}";
  }
}

class SchedulerListView extends StatelessWidget {
  final String title;
  final Map<String, List<Widget>> children;

  const SchedulerListView({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> buildingTiles = [];
    for (final building in children.keys) {
      buildingTiles.add(
        Card(
          child: ExpansionTile(
            key: PageStorageKey(building),
            title: mediumTitleText(context, building),
            children: children[building]!,
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: widePhoneWidth),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: insets8,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: buildingTiles,
                      ),
                    ),
                  );
                },
              ),
            ),
            padding8,
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Done"),
            ),
            padding8,
          ],
        ),
      ),
    );
  }
}
