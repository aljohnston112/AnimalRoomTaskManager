import 'dart:collection';
import 'dart:math';

import 'package:animal_room_task_manager/login_screen/login_use_case.dart';
import 'package:animal_room_task_manager/room_check/record_repository.dart';
import 'package:animal_room_task_manager/scheduler/pick_user_page.dart';
import 'package:animal_room_task_manager/scheduler/scheduling_building_selector_screen.dart';
import 'package:animal_room_task_manager/scheduler/scheduling_model.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:animal_room_task_manager/theme_data.dart';
import 'package:animal_room_task_manager/user_management/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../building_management/building_repository.dart';
import '../room_check/room_check_model.dart';
import '../room_check/room_check_repository.dart';
import '../room_check/room_check_screen.dart';

// 126 is the lowest width at which a single Card looks presentable
// This will need to be readjusted if the Cards change
const double minCardWidth = 126.0;

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
    final now = DateTime.now();
    return switch (_taskFrequency) {
      TaskFrequency.daily => _buildDailyTaskCardList(now, context),
      TaskFrequency.weekly => _buildWeeklyTaskCardList(now, context),
      TaskFrequency.monthly => _buildMonthlyTaskCardList(now, context),
    };
  }

  Widget _buildDailyTaskCardList(DateTime now, BuildContext context) {
    return ListenableBuilder(
      listenable: schedulingModel.taskListMapNotifier,
      builder: (context, _) {
        final taskLists = Map.fromEntries(
          schedulingModel.taskListMap.entries.where(
            (e) => e.key.frequency == TaskFrequency.daily,
          ),
        );
        final allBuildings = SplayTreeSet<Building>.from(
          taskLists.keys.map((key) => key.building),
        );

        final buildingToRoomCheckCards = SplayTreeMap<Building, List<Widget>>();
        for (final building in allBuildings) {
          buildingToRoomCheckCards[building] = [];
        }
        final numberOfDaysToDisplay = 31;
        for (int i = 0; i <= numberOfDaysToDisplay; i++) {
          final date = now.add(Duration(days: i));
          final month = date.month;
          final day = date.day;
          final year = date.year;
          var dateKey = "$month/$day/$year";
          for (final building in allBuildings) {
            final taskListsInBuilding = Map.fromEntries(
              taskLists.entries
                  .where((e) => e.key.building.name == building.name)
                  .toList(),
            );
            buildingToRoomCheckCards[building]!.add(
              _buildDateExpansionCard(
                buildContext: context,
                taskLists: taskListsInBuilding,
                dateString: dateKey,
                isCurrentPeriod: i == 0,
                date: (year: year, month: month, day: day),
              ),
            );
          }
        }
        return SchedulerBuildingSelectorScreen(
          title: "Daily Scheduler",
          children: buildingToRoomCheckCards,
          model: schedulingModel,
        );
      },
    );
  }

  Widget _buildWeeklyTaskCardList(DateTime now, BuildContext context) {
    return ListenableBuilder(
      listenable: schedulingModel.taskListMapNotifier,
      builder: (context, _) {
        final taskLists = Map.fromEntries(
          schedulingModel.taskListMap.entries.where(
            (e) => e.key.frequency == TaskFrequency.weekly,
          ),
        );
        final List<Building> allBuildings = taskLists.keys
            .map((key) => key.building)
            .toSet()
            .toList();
        allBuildings.sort();

        final buildingToRoomCheckCards = SplayTreeMap<Building, List<Widget>>();
        for (final building in allBuildings) {
          buildingToRoomCheckCards[building] = [];
        }
        var previousSunday = normalizeDate(now, TaskFrequency.weekly);
        for (int i = 0; i < 4; i++) {
          previousSunday = previousSunday.add(Duration(days: 7));
          final previousMonth = previousSunday.month;
          final previousDay = previousSunday.day;
          final previousYear = previousSunday.year;

          final saturdayAfterPreviousSunday = previousSunday.add(
            const Duration(days: 6),
          );
          final nextMonth = saturdayAfterPreviousSunday.month;
          final nextDay = saturdayAfterPreviousSunday.day;
          final nextYear = saturdayAfterPreviousSunday.year;

          var dateKey =
              "$previousMonth/$previousDay/$previousYear to "
              "$nextMonth/$nextDay/$nextYear";
          for (final building in allBuildings) {
            final taskListsInBuilding = Map.fromEntries(
              taskLists.entries
                  .where((e) => e.key.building.name == building.name)
                  .toList(),
            );
            buildingToRoomCheckCards[building]!.add(
              _buildDateExpansionCard(
                buildContext: context,
                taskLists: taskListsInBuilding,
                dateString: dateKey,
                isCurrentPeriod: i == 0,
                date: (
                  year: previousYear,
                  month: previousMonth,
                  day: previousDay,
                ),
              ),
            );
          }
        }

        return SchedulerBuildingSelectorScreen(
          title: "Weekly Scheduler",
          children: buildingToRoomCheckCards,
          model: schedulingModel,
        );
      },
    );
  }

  Widget _buildMonthlyTaskCardList(DateTime now, BuildContext context) {
    return ListenableBuilder(
      listenable: schedulingModel.taskListMapNotifier,
      builder: (context, _) {
        final taskLists = Map.fromEntries(
          schedulingModel.taskListMap.entries.where(
            (e) => e.key.frequency == TaskFrequency.monthly,
          ),
        );
        final List<Building> allBuildings = taskLists.keys
            .map((key) => key.building)
            .toSet()
            .toList();
        allBuildings.sort();

        final buildingToRoomCheckCards = SplayTreeMap<Building, List<Widget>>();
        for (final building in allBuildings) {
          buildingToRoomCheckCards[building] = [];
        }

        final String monthName = _getMonthName(now.month);
        final String dateKey = "$monthName ${now.year}";
        var isCurrentPeriod = true;

        for (final building in allBuildings) {
          final taskListsInBuilding = Map.fromEntries(
            taskLists.entries
                .where((e) => e.key.building.name == building.name)
                .toList(),
          );
          buildingToRoomCheckCards[building]!.add(
            _buildDateExpansionCard(
              buildContext: context,
              taskLists: taskListsInBuilding,
              dateString: dateKey,
              isCurrentPeriod: isCurrentPeriod,
              date: (year: now.year, month: now.month, day: 1),
            ),
          );
        }
        return SchedulerBuildingSelectorScreen(
          title: "Monthly Scheduler",
          children: buildingToRoomCheckCards,
          model: schedulingModel,
        );
      },
    );
  }

  String _getMonthName(int month) {
    const monthNames = {
      DateTime.january: "January",
      DateTime.february: "February",
      DateTime.march: "March",
      DateTime.april: "April",
      DateTime.may: "May",
      DateTime.june: "June",
      DateTime.july: "July",
      DateTime.august: "August",
      DateTime.september: "September",
      DateTime.october: "October",
      DateTime.november: "November",
      DateTime.december: "December",
    };
    return monthNames[month]!;
  }

  Widget _buildDateExpansionCard({
    required BuildContext buildContext,
    required Map<TaskListKey, TaskList> taskLists,
    required String dateString,
    required bool isCurrentPeriod,
    required RoomCheckDate date,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: insets8,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          key: PageStorageKey(dateString),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          title: mediumTitleText(buildContext, dateString),
          children: [_buildRoomCheckCardFlow(taskLists, isCurrentPeriod, date)],
        ),
      ),
    );
  }

  LayoutBuilder _buildRoomCheckCardFlow(
    Map<TaskListKey, TaskList> taskLists,
    bool isCurrentPeriod,
    RoomCheckDate date,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListenableBuilder(
          listenable: schedulingModel,
          builder: (context, _) {
            var cards = _buildRoomCheckCards(
              buildContext: context,
              taskLists: taskLists,
              isCurrentPeriod: isCurrentPeriod,
              date: date,
            );
            final cardGrid = RoomCheckCardGrid(children: cards);
            if (constraints.maxWidth < minCardWidth) {
              return SingleChildScrollView(
                key: PageStorageKey(constraints.maxWidth),
                scrollDirection: .horizontal,
                child: SizedBox(width: minCardWidth, child: cardGrid),
              );
            }
            return cardGrid;
          },
        );
      },
    );
  }

  List<Widget> _buildRoomCheckCards({
    required BuildContext buildContext,
    required Map<TaskListKey, TaskList> taskLists,
    required bool isCurrentPeriod,
    required RoomCheckDate date,
  }) {
    final List<TaskListKey> taskListKeys = taskLists.keys.toList();
    List<Widget> roomCheckCards = [];
    final logInUseCase = buildContext.read<LoginUseCase>();
    for (var taskListKey in taskListKeys) {
      final taskList = taskLists[taskListKey]!;
      final frequency = taskList.frequency;
      final TaskListState(:tasksDone, :doneBy) = schedulingModel
          .getTaskListState(taskList, taskListKey.room, date);
      String userAssignedString = _getAssignedUserString(
        schedulingModel.getUserAssignedToRoom(
          taskListKey.building,
          date,
          taskListKey.room,
          frequency,
        ),
      );
      final card = _buildRoomCheckCard(
        buildContext,
        taskListKey,
        tasksDone,
        userAssignedString,
        doneBy,
        date,
        logInUseCase,
        isCurrentPeriod,
        taskList,
      );
      roomCheckCards.add(card);
    }
    return roomCheckCards;
  }

  Card _buildRoomCheckCard(
    BuildContext context,
    TaskListKey taskListKey,
    bool tasksDone,
    String userAssignedString,
    List<User> doneBy,
    RoomCheckDate date,
    LoginUseCase logInUseCase,
    bool isCurrentPeriod,
    TaskList taskList,
  ) {
    return Card(
      elevation: appCardElevation,
      child: pad8(
        Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            mediumTitleText(context, taskListKey.room.name),
            if (!tasksDone) ...[
              padding8,
              _buildAssignedUserText(context, userAssignedString),
            ],
            padding8,
            if (tasksDone && doneBy.isNotEmpty) ...[
              mediumTitleText(context, _getDoneByString(doneBy)),
            ] else ...[
              _buildAssignButtons(taskListKey, date, logInUseCase),
            ],
            if (isCurrentPeriod && !tasksDone) ...[
              padding8,
              _buildStartButton(
                taskListKey,
                context,
                taskList,
                date,
                logInUseCase,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getAssignedUserString(String? user) {
    if (user != null) {
      return "Assigned to\n$user";
    }
    return "Unassigned";
  }

  String _getDoneByString(List<User> doneBy) {
    return "Done by ${doneBy.map((user) => user.email).join(",\n")}";
  }

  Center _buildAssignedUserText(
    BuildContext context,
    String userAssignedString,
  ) {
    return Center(
      child: mediumTitleText(context, userAssignedString, TextAlign.center),
    );
  }

  Column _buildAssignButtons(
    TaskListKey taskListKey,
    RoomCheckDate date,
    LoginUseCase logInUseCase,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAssignToMeButton(taskListKey, date, logInUseCase),
        padding8,
        _buildAssignToAnotherButton(taskListKey, date),
      ],
    );
  }

  FilledButton _buildAssignToAnotherButton(
    TaskListKey taskListKey,
    RoomCheckDate date,
  ) {
    return FilledButton(
      onPressed: () async {
        final user = await navigate(
          PickUserPage(UnmodifiableSetView(schedulingModel.users)),
        );
        if (user != null) {
          schedulingModel.assignUserToRoomCheck(
            taskListKey.building,
            date,
            taskListKey.room,
            user,
            _taskFrequency,
          );
        }
      },
      child: const Text("Assign to another", textAlign: TextAlign.center),
    );
  }

  FilledButton _buildAssignToMeButton(
    TaskListKey taskListKey,
    RoomCheckDate date,
    LoginUseCase logInUseCase,
  ) {
    return FilledButton(
      onPressed: () {
        schedulingModel.assignUserToRoomCheck(
          taskListKey.building,
          date,
          taskListKey.room,
          logInUseCase.loggedInUser!,
          _taskFrequency,
        );
      },
      child: const Text("Assign to me", textAlign: TextAlign.center),
    );
  }

  FilledButton _buildStartButton(
    TaskListKey taskListKey,
    BuildContext context,
    TaskList taskList,
    RoomCheckDate date,
    LoginUseCase logInUseCase,
  ) {
    return FilledButton(
      onPressed: () async {
        await schedulingModel.loadRoomCheckRecords(
          taskListKey.room,
          DateTime.now().toRoomCheckDate(),
          taskListKey.frequency,
        );
        if (context.mounted) {
          await navigate(
            RoomCheckScreen(
              roomCheckModel: RoomCheckModel(
                building: taskListKey.building,
                room: taskListKey.room,
                taskList: taskList,
                recordRepository: context.read(),
                roomCheckRepository: context.read(),
                date: date,
                loginUseCase: logInUseCase,
              ),
            ),
          );
        }
        // Reload after finishing, as there may be updates
        await schedulingModel.refreshData();
      },
      child: const Text("Start"),
    );
  }
}

class RoomCheckCardGrid extends MultiChildRenderObjectWidget {
  const RoomCheckCardGrid({super.key, required super.children});

  @override
  RoomCheckCardGridRenderBox createRenderObject(BuildContext context) {
    return RoomCheckCardGridRenderBox();
  }
}

class RoomCheckCardGridRenderBox extends RenderBox
    with
        ContainerRenderObjectMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        >,
        RenderBoxContainerDefaultsMixin<
          RenderBox,
          ContainerBoxParentData<RenderBox>
        > {
  double _maxWidth = 0.0;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ContainerBoxParentData<RenderBox>) {
      child.parentData = MultiChildLayoutParentData();
    }
  }

  @override
  void performLayout() {
    if (childCount == 0) {
      size = constraints.smallest;
      return;
    }
    final measureConstraints = BoxConstraints(
      minWidth: 0,
      maxWidth: double.infinity,
      minHeight: 0,
      maxHeight: double.infinity,
    );
    _runFullEvaluationPass(measureConstraints);
    _layoutAndPosition(
      BoxConstraints(
        minWidth: 0,
        maxWidth: _maxWidth,
        minHeight: 0,
        maxHeight: constraints.maxHeight,
      ),
    );
  }

  void _runFullEvaluationPass(BoxConstraints childConstraints) {
    double maxWidth = 0.0;
    RenderBox? maxWidthChild;

    RenderBox? child = firstChild;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      if (child.size.width > maxWidth) {
        maxWidth = child.size.width;
        maxWidthChild = child;
      }
      final childParentData =
          child.parentData! as ContainerBoxParentData<RenderBox>;
      child = childParentData.nextSibling;
    }
    _maxWidth = maxWidth;
  }

  void _layoutAndPosition(BoxConstraints childConstraints) {
    final List<RenderBox> childrenList = [];
    RenderBox? child = firstChild;
    while (child != null) {
      childrenList.add(child);
      child =
          (child.parentData! as ContainerBoxParentData<RenderBox>).nextSibling;
    }

    if (childrenList.isEmpty) {
      size = constraints.smallest;
      return;
    }

    // 249 is the lowest width at which text in the Cards looks presentable
    // This will need to be readjusted if the Cards change
    final columnCount = constraints.maxWidth < 249
        ? 1
        : max(2, constraints.maxWidth ~/ _maxWidth);
    final xDelta = constraints.maxWidth < minCardWidth
        ? minCardWidth
        : constraints.maxWidth / columnCount;

    Map<(int, int), double> childHeights = {};
    for (int i = 0; i < childrenList.length; i++) {
      final int rowIndex = i ~/ columnCount;
      final int columnIndex = i % columnCount;
      final RenderBox currentChild = childrenList[i];
      currentChild.layout(
        childConstraints.copyWith(maxWidth: xDelta),
        parentUsesSize: true,
      );
      childHeights[(rowIndex, columnIndex)] = currentChild.size.height;
    }

    int lastRowIndex = 0;
    Map<int, double> currentYOffsetPerColumn = {};
    for (int i = 0; i < columnCount; i++) {
      currentYOffsetPerColumn[i] = 0.0;
    }
    for (int i = 0; i < childrenList.length; i++) {
      final int rowIndex = i ~/ columnCount;
      final int columnIndex = i % columnCount;
      if (rowIndex != lastRowIndex) {
        lastRowIndex = rowIndex;
      }
      final currentYOffset = currentYOffsetPerColumn[columnIndex]!;
      currentYOffsetPerColumn[columnIndex] =
          currentYOffsetPerColumn[columnIndex]! +
          childHeights[(rowIndex, columnIndex)]!;

      final RenderBox currentChild = childrenList[i];
      final ContainerBoxParentData<RenderBox> childParentData =
          currentChild.parentData! as ContainerBoxParentData<RenderBox>;
      final double xOffset = columnIndex * xDelta;
      childParentData.offset = Offset(xOffset, currentYOffset);
    }
    double currentYOffset = 0.0;
    for (int i = 0; i < columnCount; i++) {
      currentYOffset = max(currentYOffset, currentYOffsetPerColumn[i]!);
    }
    size = constraints.constrain(Size(xDelta * columnCount, currentYOffset));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
