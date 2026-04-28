import 'dart:collection';

import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../scheduler/scheduling_model.dart';

enum TaskFrequency { daily, weekly, monthly }

extension TaskFrequencyExtension on TaskFrequency {
  String get toDbString {
    switch (this) {
      case TaskFrequency.daily:
        return 'Daily';
      case TaskFrequency.weekly:
        return 'Weekly';
      case TaskFrequency.monthly:
        return 'Monthly';
    }
  }
}

extension TaskFrequencyParser on String {
  TaskFrequency get toTaskFrequency {
    switch (this) {
      case 'Daily':
        return TaskFrequency.daily;
      case 'Weekly':
        return TaskFrequency.weekly;
      case 'Monthly':
        return TaskFrequency.monthly;
      default:
        throw ArgumentError('Invalid RoomCheckState string: $this');
    }
  }
}

class Task {
  final int tid;
  final String description;
  final bool managerOnly;

  Task({
    required this.description,
    required this.managerOnly,
    required this.tid,
  });

  @override
  bool operator ==(Object other) => (other is Task && tid == other.tid);

  @override
  int get hashCode => tid.hashCode;
}

class QuantitativeRange<T> {
  final T min;
  final T max;
  final String units;
  final bool isRequired;

  QuantitativeRange({
    required this.min,
    required this.max,
    required this.units,
    required this.isRequired,
  });
}

class QuantitativeTask<T> extends Task {
  final List<QuantitativeRange<T>> ranges;

  QuantitativeTask({
    required super.description,
    required this.ranges,
    required super.managerOnly,
    required super.tid,
  });

  @override
  bool operator ==(Object other) =>
      (other is QuantitativeTask && tid == other.tid);

  @override
  int get hashCode => tid.hashCode;
}

Task parseTask(PostgrestMap taskDB, int tid) {
  final taskName = taskDB['task_name'];
  final isManagerTask = taskDB['manager_only'];
  final quantitativeRangesDB = taskDB['quantitative_ranges'];
  List<QuantitativeRange> quantitativeRanges = [];
  if (quantitativeRangesDB != null) {
    final unit = quantitativeRangesDB['unit'];
    final warningRangeDB = quantitativeRangesDB['warning_range'];
    QuantitativeRange? warningRange;
    if (warningRangeDB != null) {
      warningRange = QuantitativeRange(
        min: warningRangeDB['min'],
        max: warningRangeDB['max'],
        units: unit,
        isRequired: false,
      );
      quantitativeRanges.add(warningRange);
    }
    final requiredRangeDB = quantitativeRangesDB['required_range'];
    QuantitativeRange? requiredRange;
    if (requiredRangeDB != null) {
      requiredRange = QuantitativeRange(
        min: requiredRangeDB['min'],
        max: requiredRangeDB['max'],
        units: unit,
        isRequired: true,
      );
      quantitativeRanges.add(requiredRange);
    }
    return QuantitativeTask(
      description: taskName,
      ranges: quantitativeRanges,
      managerOnly: isManagerTask,
      tid: tid,
    );
  } else {
    return Task(description: taskName, managerOnly: isManagerTask, tid: tid);
  }
}

class TaskList {
  final int tlid;
  final String name;
  final TaskFrequency frequency;
  final UnmodifiableListView<Task> tasks;

  TaskList({
    required this.tlid,
    required this.name,
    required this.frequency,
    required this.tasks,
  });

  @override
  bool operator ==(Object other) => other is TaskList && other.tlid == tlid;

  @override
  int get hashCode => tlid.hashCode;
}

class TaskListKey {
  final String buildingName;
  final Room room;
  final TaskFrequency frequency;

  TaskListKey({
    required this.buildingName,
    required this.room,
    required this.frequency,
  });

  @override
  bool operator ==(Object other) {
    return other is TaskListKey &&
        other.buildingName == buildingName &&
        other.room == room &&
        other.frequency == frequency;
  }

  @override
  int get hashCode =>
      Object.hash(buildingName.hashCode, room.hashCode, frequency.hashCode);
}

class TaskListRepository {
  final Database _database;

  final List<Task> _tasks = [];
  final ValueNotifier<UnmodifiableListView<Task>> tasks = ValueNotifier(
    UnmodifiableListView([]),
  );

  final Map<TaskListKey, TaskList> _taskListMap = {};
  final ValueNotifier<UnmodifiableMapView<TaskListKey, TaskList>> taskListMap =
      ValueNotifier(UnmodifiableMapView({}));
  final ValueNotifier<UnmodifiableMapView<TaskFrequency, Set<TaskList>>>
  taskLists = ValueNotifier(UnmodifiableMapView({}));

  TaskListRepository({required Database database}) : _database = database;

  Future<void> loadTaskLists() async {
    _taskListMap.clear();
    final map = await _database.getTaskLists();
    for (final buildingMap in map) {
      final bid = buildingMap['b_id'];
      final buildingName = buildingMap['building_name'];
      final taskListsByFrequency = buildingMap['task_lists_by_frequency'];
      for (final taskListsWithFrequency in taskListsByFrequency) {
        final frequency =
            (taskListsWithFrequency['frequency'] as String).toTaskFrequency;
        final taskLists = taskListsWithFrequency['task_lists'];
        for (final taskList in taskLists) {
          final tlid = taskList['tl_id'];
          final taskListName = taskList['task_list_name'];
          final roomsDB = taskList['rooms'];
          final tasksDB = taskList['tasks'];
          // Rooms with the task list
          List<Room> rooms = [];
          for (final roomDB in roomsDB) {
            rooms.add(Room(rid: roomDB['r_id'], name: roomDB['room_name']));
          }
          // Tasks in the task list
          List<Task> tasks = [];
          if (tasksDB != null) {
            for (final taskDB in tasksDB) {
              final tid = taskDB['t_id'];
              tasks.add(parseTask(taskDB, tid));
            }
            TaskList taskList = TaskList(
              tlid: tlid,
              name: taskListName,
              frequency: frequency,
              tasks: UnmodifiableListView(tasks),
            );
            for (final room in rooms) {
              TaskListKey taskListKey = TaskListKey(
                buildingName: buildingName,
                room: room,
                frequency: frequency,
              );
              _taskListMap[taskListKey] = taskList;
            }
          }
        }
      }
    }
    taskListMap.value = UnmodifiableMapView(_taskListMap);
    taskLists.value = UnmodifiableMapView(
      _taskListMap.values.fold({}, (
        previousValue,
        task,
      ) {
        previousValue.putIfAbsent(task.frequency, () => {}).add(task);
        return previousValue;
      }),
    );
  }

  Future<void> loadTasks() async {
    final map = await _database.getTasks();
    for (final taskMap in map) {
      final taskMapDB = taskMap['jsonb_build_object'];
      final tid = taskMapDB['t_id'];
      _tasks.add(parseTask(taskMapDB, tid));
    }
    tasks.value = UnmodifiableListView(_tasks);
  }

  Future<void> addTaskList(
    String taskListName,
    TaskFrequency frequency,
    Map<int, int> tidToIndex,
  ) async {
    _database.insertTaskList(taskListName, frequency, tidToIndex);
  }

  Future<void> deleteTaskList(TaskList taskList) async {
    _database.deleteTaskList(taskList);
  }

  Future<void> undeleteTaskList(String taskListName) async {
    _database.undeleteTaskList(taskListName);
  }
}
