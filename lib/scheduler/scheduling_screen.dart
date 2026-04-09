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
      cards.add(
        _buildRoomAssignmentCard(
          context,
          TaskListRepository.roomToDailyTaskLists,
          dateKey,
          i == 0,
          (year: year, month: month, day: day),
        ),
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
      cards.add(
        _buildRoomAssignmentCard(
          context,
          TaskListRepository.roomToWeeklyTaskLists,
          dateKey,
          i == 0,
          (year: nextYear, month: nextMonth, day: nextDay),
        ),
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
    return SchedulerListView(
      title: "Monthly Scheduler",
      children: [
        _buildRoomAssignmentCard(
          context,
          TaskListRepository.roomToMonthlyTaskLists,
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

  Widget _buildRoomAssignmentCard(
    BuildContext context,
    Map<String, TaskList> roomToTaskList,
    String dateString,
    bool isCurrentPeriod,
    RoomCheckDate date,
  ) {
    return Card(
      child: Padding(
        padding: insets8,
        child: ExpansionTile(
          key: PageStorageKey(dateString),
          expandedAlignment: Alignment.centerLeft,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: mediumTitleText(context, dateString),
          children: _buildRoomAssignmentTiles(
            context,
            roomToTaskList,
            isCurrentPeriod,
            date,
            _taskFrequency,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRoomAssignmentTiles(
    BuildContext context,
    Map<String, TaskList> roomToTaskLists,
    bool isCurrentPeriod,
    RoomCheckDate date,
    TaskFrequency frequency,
  ) {
    final List<String> roomNames = roomToTaskLists.keys.toList();

    return roomNames.map((roomName) {
      var roomTaskList = roomToTaskLists[roomName]!;
      return Selector2(
        selector: (context, RecordRepository rr, RoomCheckRepository rcr) {
          var recordMap = context.select(
            (RecordRepository r) => r.getRecordsForRoom(roomName, date),
          );
          bool done = roomTaskList.tasks.every(
            (t) => recordMap.keys.contains(t),
          );
          User doneBy = recordMap.values.first.doneBy;
          return (done, doneBy);
        },
        builder: (context, data, c) {
          var (done, doneBy) = data;
          var logInUseCase = context.read<LoginUseCase>();
          return ListenableBuilder(
            listenable: schedulingModel,
            builder: (context, _) => Card(
              child: Padding(
                padding: insets8,
                child: Column(
                  children: [
                    mediumTitleText(context, roomName),
                    if (!done) ...[
                      padding8,
                      mediumTitleText(
                        context,
                        _getAssignedUserString(
                          schedulingModel.geUserAssignedToRoom(
                            date,
                            roomName,
                            frequency,
                          ),
                        ),
                      ),
                    ],
                    padding8,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (done) ...[
                          mediumTitleText(context, _getDoneByString(doneBy)),
                        ] else ...[
                          _buildAssignmentButton(context, date, roomName),
                        ],
                        if (isCurrentPeriod && !done) ...[
                          FilledButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) {
                                    return RoomCheckScreen(
                                      roomCheckModel: RoomCheckModel(
                                        roomName: roomName,
                                        taskList: roomTaskList,
                                        recordRepository: context
                                            .read<RecordRepository>(),
                                        date: date,
                                        loginUseCase: logInUseCase,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            child: const Text("Start"),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildAssignmentButton(
    BuildContext context,
    RoomCheckDate date,
    String roomName,
  ) {
    final loginUseCase = context.watch<LoginUseCase>();
    return Column(
      children: [
        FilledButton(
          onPressed: () {
            schedulingModel.assignUserToRoomCheck(
              date,
              roomName,
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

  String _getAssignedUserString(User? user) {
    if (user != null) {
      return "Assigned to ${user.email}";
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
