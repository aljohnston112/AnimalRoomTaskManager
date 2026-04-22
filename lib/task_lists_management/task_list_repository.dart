import 'dart:collection';

import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:flutter/material.dart';

import '../scheduler/scheduling_model.dart';

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

class Task {
  final int tid;
  final String description;
  final bool managerOnly;
  final TaskFrequency frequency;

  Task({
    required this.description,
    required this.managerOnly,
    required this.tid,
    required this.frequency,
  });
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
    required super.frequency,
  });
}

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

class TaskList {
  final String name;
  final TaskFrequency frequency;
  final UnmodifiableListView<Task> tasks;

  TaskList({required this.name, required this.frequency, required this.tasks});
}

class TaskListRepository extends ChangeNotifier {
  final Database _database;
  final Map<TaskListKey, TaskList> taskLists = {};

  TaskListRepository({required Database database}) : _database = database;

  Future<void> loadTaskLists() async {
    taskLists.clear();
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
            for (final task in tasksDB) {
              final tid = task['t_id'];
              final taskName = task['task_name'];
              final isManagerTask = task['manager_only'];
              final quantitativeRangesDB = task['quantitative_ranges'];
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
                tasks.add(
                  QuantitativeTask(
                    description: taskName,
                    ranges: quantitativeRanges,
                    managerOnly: isManagerTask,
                    tid: tid,
                    frequency: frequency,
                  ),
                );
              } else {
                tasks.add(
                  Task(
                    description: taskName,
                    managerOnly: isManagerTask,
                    tid: tid,
                    frequency: frequency,
                  ),
                );
              }

              TaskList taskList = TaskList(
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
                this.taskLists[taskListKey] = taskList;
              }
            }
          }
        }
      }
    }
  }
}
