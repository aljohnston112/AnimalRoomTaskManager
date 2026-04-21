import 'package:animal_room_task_manager/login_screen/login_use_case.dart';
import 'package:animal_room_task_manager/room_check/record_repository.dart';
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
      onPressed: () {
        Navigator.push(
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
      onPressed: () {
        Navigator.push(
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
      onPressed: () {
        Navigator.push(
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
    switch (_taskFrequency) {
      case TaskFrequency.daily:
        return _buildDailyTaskCardList(now, context);
      case TaskFrequency.weekly:
        return _buildWeeklyTaskCardList(now, context);
      case TaskFrequency.monthly:
        return _buildMonthlyTaskCardList(now, context);
    }
  }

  SchedulerListView _buildDailyTaskCardList(
    DateTime now,
    BuildContext context,
  ) {
    List<Widget> cards = [];
    for (int i = 0; i < 32; i++) {
      final date = now.add(Duration(days: i));
      final month = date.month;
      final day = date.day;
      final year = date.year;
      var dateKey = "$month/$day/$year";
      final taskLists = context
          .watch<TaskListRepository>()
          .taskLists;
      cards.add(
        _buildRoomAssignmentCards(context, buildingName, taskLists, dateKey, i == 0, (
          year: year,
          month: month,
          day: day,
        )),
      );
    }
    return SchedulerListView(title: "Daily Scheduler", children: cards);
  }

  SchedulerListView _buildWeeklyTaskCardList(
    DateTime now,
    BuildContext context,
  ) {
    List<Widget> cards = [];
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
      final taskLists = context
          .watch<TaskListRepository>()
          .roomToWeeklyTaskLists;
      cards.add(
        _buildRoomAssignmentCards(context, buildingName, taskLists, dateKey, i == 0, (
          year: nextYear,
          month: nextMonth,
          day: nextDay,
        )),
      );
    }
    return SchedulerListView(title: "Weekly Scheduler", children: cards);
  }

  SchedulerListView _buildMonthlyTaskCardList(
    DateTime now,
    BuildContext context,
  ) {
    final String monthName = _getMonthName(now.month);
    final String dateKey = "$monthName ${now.year}";

    var isCurrentPeriod = true;
    final taskLists = context
        .watch<TaskListRepository>()
        .roomToMonthlyTaskLists;
    return SchedulerListView(
      title: "Monthly Scheduler",
      children: [
        _buildRoomAssignmentCards(
          context,
          buildingName,
          taskLists,
          dateKey,
          isCurrentPeriod,
          (year: now.year, month: now.month, day: 1),
        ),
      ],
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
    String buildingName,
    Map<Room, TaskList> roomToTaskList,
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
            buildingName,
            roomToTaskList,
            isCurrentPeriod,
            date
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRoomAssignmentTiles(
    BuildContext context,
    String buildingName,
    Map<Room, TaskList> roomToTaskLists,
    bool isCurrentPeriod,
    RoomCheckDate date,
  ) {
    final List<Room> rooms = roomToTaskLists.keys.toList();
    List<Widget> cards = [];
    for (var room in rooms) {
      final roomTaskList = roomToTaskLists[room]!;
      final frequency = roomTaskList.frequency;
      cards.add(
        ListenableBuilder(
          listenable: schedulingModel,
          builder: (context, _) {
            var logInUseCase = context.read<LoginUseCase>();
            final TaskListState(:tasksDone, :doneBy) = schedulingModel
                .getTaskListState(roomTaskList, room, date);
            return Card(
              child: Padding(
                padding: insets8,
                child: Column(
                  children: [
                    mediumTitleText(context, room.name),
                    if (!tasksDone) ...[
                      padding8,
                      mediumTitleText(
                        context,
                        _getAssignedUserString(
                          schedulingModel.getUserAssignedToRoom(
                            date,
                            room.name,
                            frequency,
                          ),
                        ),
                      ),
                    ],
                    padding8,
                    if (tasksDone && doneBy != null) ...[
                      mediumTitleText(context, _getDoneByString(doneBy)),
                    ] else ...[
                      _buildAssignmentButton(context, date, room),
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
                                    buildingName: buildingName,
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
      child: Center(
        child: Column(
          children: [
            Expanded(
              child: ConstrainedBox(
                // To prevent the list from taking up the full width of a wide screen
                constraints: const BoxConstraints(maxWidth: widePhoneWidth),
                child: ListView(
                  shrinkWrap: true,
                  padding: insets8,
                  children: children,
                ),
              ),
            ),
            padding8,
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Done"),
            ),
            padding8,
          ],
        ),
      ),
    );
  }
}
