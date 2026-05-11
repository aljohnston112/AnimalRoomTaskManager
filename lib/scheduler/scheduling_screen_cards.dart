import 'dart:collection';

import 'package:animal_room_task_manager/login_screen/login_use_case.dart';
import 'package:animal_room_task_manager/scheduler/pick_user_page.dart';
import 'package:animal_room_task_manager/scheduler/scheduling_model.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:animal_room_task_manager/theme_data.dart';
import 'package:animal_room_task_manager/user_management/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../room_check/room_check_model.dart';
import '../room_check/room_check_repository.dart';
import '../room_check/room_check_screen.dart';

class SchedulingScreenCards extends StatelessWidget {
  final SchedulingModel schedulingModel;
  final TaskFrequency _taskFrequency;
  final numberOfColumns = 2;

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
      makeScrollable: false,
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

  SchedulingBuildingSelectorScreen _buildDailyTaskCardList(
    DateTime now,
    BuildContext context,
  ) {
    final taskLists = Map.fromEntries(
      context.watch<TaskListRepository>().taskListMap.value.entries.where(
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
        final taskSInBuilding = Map.fromEntries(
          taskLists.entries
              .where((e) => e.key.buildingName == building)
              .toList(),
        );
        cards[building]!.add(
          _buildRoomAssignmentCards(context, taskSInBuilding, dateKey, i == 0, (
            year: year,
            month: month,
            day: day,
          )),
        );
      }
    }
    return SchedulingBuildingSelectorScreen(
      title: "Daily Scheduler",
      children: cards,
    );
  }

  SchedulingBuildingSelectorScreen _buildWeeklyTaskCardList(
    DateTime now,
    BuildContext context,
  ) {
    final taskLists = Map.fromEntries(
      context.watch<TaskListRepository>().taskListMap.value.entries.where(
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
    var previousSunday = normalizeDate(now, TaskFrequency.weekly);
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
            year: previousYear,
            month: previousMonth,
            day: previousDay,
          )),
        );
      }
    }

    return SchedulingBuildingSelectorScreen(
      title: "Weekly Scheduler",
      children: cards,
    );
  }

  SchedulingBuildingSelectorScreen _buildMonthlyTaskCardList(
    DateTime now,
    BuildContext context,
  ) {
    final taskLists = Map.fromEntries(
      context.watch<TaskListRepository>().taskListMap.value.entries.where(
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
    return SchedulingBuildingSelectorScreen(
      title: "Monthly Scheduler",
      children: cards,
    );
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
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                schedulingModel.resetMaxWidth();
                double tileWidth = constraints.maxWidth / numberOfColumns;
                var tiles = _buildRoomAssignmentTiles(
                  context,
                  taskLists,
                  isCurrentPeriod,
                  date,
                  tileWidth,
                );
                return ListenableBuilder(
                  listenable: schedulingModel.maxHeight,
                  builder: (context, _) {
                    return Wrap(
                      children: tiles
                          .map(
                            (tile) => SizedBox(
                              width: tileWidth,
                              height: schedulingModel.maxHeight.value,
                              child: tile,
                            ),
                          )
                          .toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRoomAssignmentTiles(
    BuildContext context,
    Map<TaskListKey, TaskList> taskLists,
    bool isCurrentPeriod,
    RoomCheckDate date,
    double width,
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
            final logInUseCase = context.read<LoginUseCase>();
            final TaskListState(:tasksDone, :doneBy) = schedulingModel
                .getTaskListState(roomTaskList, key.room, date);
            String userAssignedString = _getAssignedUserString(
              schedulingModel.getUserAssignedToRoom(
                key.buildingName,
                date,
                key.room,
                frequency,
              ),
            );
            final card = Card(
              child: Padding(
                padding: insets8,
                child: Column(
                  children: [
                    mediumTitleText(context, key.room.name),
                    if (!tasksDone) ...[
                      padding8,
                      Center(child:
                      mediumTitleText(context, userAssignedString, TextAlign.center),)
                    ],
                    padding8,
                    if (tasksDone && doneBy != null) ...[
                      mediumTitleText(context, _getDoneByString(doneBy)),
                    ] else ...[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FilledButton(
                            onPressed: () {
                              schedulingModel.assignUserToRoomCheck(
                                key.buildingName,
                                date,
                                key.room,
                                logInUseCase.loggedInUser!,
                                _taskFrequency,
                              );
                            },
                            child: const Text("Assign to me", textAlign: TextAlign.center,),
                          ),
                          padding8,
                          FilledButton(
                            onPressed: () async {
                              final user = await navigate(
                                PickUserPage(
                                  UnmodifiableSetView(
                                    schedulingModel.users.value,
                                  ),
                                ),
                              );
                              if (user != null) {
                                schedulingModel.assignUserToRoomCheck(
                                  key.buildingName,
                                  date,
                                  key.room,
                                  user,
                                  _taskFrequency,
                                );
                              }
                            },
                            child: const Text("Assign to another", textAlign: TextAlign.center,),
                          ),
                        ],
                      ),
                    ],
                    if (isCurrentPeriod && !tasksDone) ...[
                      padding8,
                      FilledButton(
                        onPressed: () async {
                          await schedulingModel.refreshData();
                          if (context.mounted) {
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
                          }
                          // Reload after finishing, as there may be updates
                          await schedulingModel.refreshData();
                        },
                        child: const Text("Start"),
                      ),
                    ],
                  ],
                ),
              ),
            );
            schedulingModel.updateMaxHeight(
              widget: card,
              width: width,
              stringLength: userAssignedString.length,
              isUnassigned: userAssignedString == "Unassigned",
            );
            return card;
          },
        ),
      );
    }
    return cards;
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

class SchedulingBuildingSelectorScreen extends StatelessWidget {
  final String title;
  final Map<String, List<Widget>> children;

  const SchedulingBuildingSelectorScreen({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final buildings = children.keys.toList()..sort();

    return buildScaffold(
      makeScrollable: false,
      title: title,
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: insets8,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              shrinkWrap: true,
              itemCount: buildings.length,
              itemBuilder: (context, index) {
                final building = buildings[index];
                return Center(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SchedulerListView(
                            title: building,
                            children: children[building]!,
                          ),
                        ),
                      );
                    },
                    child: Text(building),
                  ),
                );
              },
            ),
          ),
          FilledButton(
            onPressed: () {
              unNavigate();
            },
            child: Text("Go back"),
          ),
        ],
      ),
    );
  }
}

class SchedulerListView extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SchedulerListView({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: title,
      makeScrollable: false,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: insets8,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: children,
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
    );
  }
}
