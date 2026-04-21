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
  int get hashCode => Object.hash(
    buildingName.hashCode,
    room.hashCode,
    frequency.hashCode,
  );
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
    this.taskLists.clear();
    final roomCheckSlots = await _database.getTaskLists();
    for (final roomCheck in roomCheckSlots) {
      TaskFrequency frequency =
          (roomCheck['frequency'] as String).toTaskFrequency;
      Map<int, List<Task>> tasks = {};
      for (final task in roomCheck['tasks']) {
        final quant = task['quantitative'];

        final tid = task['t_id'];
        if (!tasks.containsKey(tid)) {
          tasks[tid] = [];
        }
        final taskName = task['task_name'];
        final isManagerTask = task['manager_only'];
        if (quant != null) {
          tasks[tid]!.add(
            QuantitativeTask(
              tid: tid,
              description: taskName,
              ranges: [
                QuantitativeRange(
                  min: quant['min'],
                  max: quant['max'],
                  units: quant['unit'],
                  isRequired: false,
                ),
              ],
              managerOnly: isManagerTask,
              frequency: frequency,
            ),
          );
        } else {
          tasks[tid]!.add(
            Task(
              tid: tid,
              description: taskName,
              managerOnly: isManagerTask,
              frequency: frequency,
            ),
          );
        }
      }

      // Any quantitative tasks with more than 1 range hae 2 ranges
      // One range for warning the user of an out of range value,
      // and another range that the user cannot record a value out of
      List<Task> flattenedTasks = [];
      for (final MapEntry(key: _, value: tasks) in tasks.entries) {
        if (tasks.length == 1) {
          flattenedTasks.add(tasks.first);
        } else {
          final task = tasks.first;
          List<QuantitativeRange> ranges = [];
          for (final task in tasks) {
            ranges.addAll((task as QuantitativeTask).ranges);
          }
          flattenedTasks.add(
            QuantitativeTask(
              description: task.description,
              ranges: ranges,
              managerOnly: task.managerOnly,
              tid: task.tid,
              frequency: frequency
            ),
          );
        }
      }

      TaskList taskList = TaskList(
        name: roomCheck['task_list_name'],
        frequency: frequency,
        tasks: UnmodifiableListView(flattenedTasks),
      );
      Room room = Room(
        rid: roomCheck['r_id'],
        name: roomCheck['room_name'],
      );
      TaskListKey taskListKey = TaskListKey(buildingName: buildingName, room: room, frequency: frequency)
      switch (frequency) {
        case TaskFrequency.daily:
          this.taskLists[room] = taskList;
          break;
        case TaskFrequency.weekly:
          roomToWeeklyTaskLists[room] = taskList;
          break;
        case TaskFrequency.monthly:
          roomToMonthlyTaskLists[room] = taskList;
      }
    }
  }
}
