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
  final QuantitativeRange<T>? warningRange;
  final QuantitativeRange<T>? requiredRange;

  QuantitativeTask({
    required super.description,
    required super.managerOnly,
    required super.tid,
    required this.warningRange,
    required this.requiredRange,
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
  QuantitativeRange? warningRange;
  QuantitativeRange? requiredRange;
  if (quantitativeRangesDB != null) {
    final unit = quantitativeRangesDB['unit'];
    final warningRangeDB = quantitativeRangesDB['warning_range'];
    if (warningRangeDB != null) {
      warningRange = QuantitativeRange(
        min: warningRangeDB['min'],
        max: warningRangeDB['max'],
        units: unit,
        isRequired: false,
      );
    }
    final requiredRangeDB = quantitativeRangesDB['required_range'];
    if (requiredRangeDB != null) {
      requiredRange = QuantitativeRange(
        min: requiredRangeDB['min'],
        max: requiredRangeDB['max'],
        units: unit,
        isRequired: true,
      );
    }
    return QuantitativeTask(
      description: taskName,
      managerOnly: isManagerTask,
      tid: tid,
      warningRange: warningRange,
      requiredRange: requiredRange,
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

  final Set<Task> _tasks = {};
  final ValueNotifier<UnmodifiableSetView<Task>> tasks = ValueNotifier(
    UnmodifiableSetView({}),
  );

  final Map<TaskListKey, TaskList> _taskListMap = {};
  final ValueNotifier<UnmodifiableMapView<TaskListKey, TaskList>> taskListMap =
      ValueNotifier(UnmodifiableMapView({}));
  final Map<TaskFrequency, Set<TaskList>> _taskLists = {};
  final ValueNotifier<UnmodifiableMapView<TaskFrequency, Set<TaskList>>>
  taskLists = ValueNotifier(UnmodifiableMapView({}));

  TaskListRepository({required Database database}) : _database = database {
    _database.subscribeToTaskLists((data) {
      bool? deleted = data.newRecord['deleted'];
      if (deleted == true) {
        _taskListMap.removeWhere((k, v) => v.tlid == data.newRecord['tl_id']);
        _taskLists.forEach(
          (k, v) => v.removeWhere((v) => v.tlid == data.newRecord['tl_id']),
        );
      }
      _updateTaskLists();
    });
    _database.subscribeToTaskListsFull((data) {
      final payload = data['payload'];
      final tlid = payload['tl_id'];
      final taskListName = payload['task_list_name'];
      final frequency = (payload['frequency'] as String).toTaskFrequency;
      final List<Task> tasks = [];
      for (final task in payload['tasks']) {
        tasks.add(parseTask(task, task['t_id']));
      }
      final taskList = TaskList(
        tlid: tlid,
        name: taskListName,
        frequency: frequency,
        tasks: UnmodifiableListView(tasks),
      );

      _taskListMap.removeWhere(
        (k, v) => v.name == taskListName && v.frequency == frequency,
      );
      List<TaskList> unassignedTasks = [];
      if (payload['buildings'] != null) {
        for (final building in payload['buildings']) {
          final bid = building['b_id'];
          final buildingName = building['building_name'];
          for (final roomDB in building['rooms']) {
            final room = Room(rid: roomDB['r_id'], name: roomDB['room_name']);
            TaskListKey key = TaskListKey(
              buildingName: buildingName,
              room: room,
              frequency: frequency,
            );
            _taskListMap[key] = taskList;
          }
        }
      } else {
        unassignedTasks.add(taskList);
      }
      _updateTaskLists(unassignedTaskLists: unassignedTasks);
    });
  }

  Future<void> loadTaskLists() async {
    _taskListMap.clear();
    taskLists.value = UnmodifiableMapView({});
    final map = await _database.getTaskLists();
    List<TaskList> unassignedTaskLists = [];
    for (final buildingMap in map) {
      final bid = buildingMap['b_id'];
      final buildingName = buildingMap['building_name'];
      final taskListsByFrequency = buildingMap['task_lists_by_frequency'];
      for (final taskListsWithFrequency in taskListsByFrequency) {
        final frequency =
            (taskListsWithFrequency['frequency'] as String).toTaskFrequency;
        final taskLists = taskListsWithFrequency['task_lists'];
        if (taskLists != null) {
          for (final taskListDB in taskLists) {
            final tlid = taskListDB['tl_id'];
            final taskListName = taskListDB['task_list_name'];
            final tasksDB = taskListDB['tasks'];

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

              final roomsDB = taskListDB['rooms'];
              // Rooms with the task list
              List<Room> rooms = [];
              if (roomsDB != null) {
                for (final roomDB in roomsDB) {
                  rooms.add(
                    Room(rid: roomDB['r_id'], name: roomDB['room_name']),
                  );
                }
                for (final room in rooms) {
                  TaskListKey taskListKey = TaskListKey(
                    buildingName: buildingName,
                    room: room,
                    frequency: frequency,
                  );
                  _taskListMap[taskListKey] = taskList;
                }
              } else {
                unassignedTaskLists.add(taskList);
              }
            }
          }
        }
      }
    }
    _updateTaskLists(unassignedTaskLists: unassignedTaskLists);
  }

  void _updateTaskLists({List<TaskList>? unassignedTaskLists}) {
    unassignedTaskLists ??= [];
    taskListMap.value = UnmodifiableMapView(_taskListMap);
    Map<TaskFrequency, Set<TaskList>> newTaskLists = Map.from(_taskLists);
    newTaskLists.addAll(
      _taskListMap.values.fold(newTaskLists, (previousValue, taskList) {
        previousValue.putIfAbsent(taskList.frequency, () => {}).add(taskList);
        return previousValue;
      }),
    );
    for (final taskList in unassignedTaskLists) {
      newTaskLists.putIfAbsent(taskList.frequency, () => {}).add(taskList);
    }
    _taskLists.addAll(newTaskLists);
    taskLists.value = UnmodifiableMapView(_taskLists);
  }

  Future<void> loadTasks() async {
    final map = await _database.getTasks();
    for (final taskMap in map) {
      final taskMapDB = taskMap['jsonb_build_object'];
      final tid = taskMapDB['t_id'];
      _tasks.add(parseTask(taskMapDB, tid));
    }
    tasks.value = UnmodifiableSetView(_tasks);
  }

  Future<void> addTaskList(
    String taskListName,
    TaskFrequency frequency,
    Map<int, int> tidToIndex,
  ) async {
    await _database.insertTaskList(taskListName, frequency, tidToIndex);
  }

  Future<void> editTaskList(
    int tlid,
    String taskListName,
    TaskFrequency taskFrequency,
    Map<int, int> tidToIndex,
  ) async {
    await _database.editTaskList(tlid, taskListName, taskFrequency, tidToIndex);
  }

  Future<void> reorderTasks(int tlid, Map<int, int> tidToIndex) async {
    await _database.reorderTasks(tlid, tidToIndex);
  }

  Future<void> deleteTaskList(TaskList taskList) async {
    await _database.deleteTaskList(taskList);
  }

  Future<void> undeleteTaskList(TaskList taskList) async {
    await _database.undeleteTaskList(taskList);
  }

  bool taskDescriptionExists(String value) {
    return _tasks.any((t) => t.description == value);
  }

  Future<void> addQuantitativeTask(
    String description,
    bool isManagerOnly,
    QuantitativeRange<double> warningRange,
    QuantitativeRange<double> requiredRange,
  ) async {
    _database.addQuantitativeTask(
      description,
      isManagerOnly,
      warningRange,
      requiredRange,
    );
  }

  Future<void> addTask(String description, bool isManagerOnly) async {
    _database.addTask(description, isManagerOnly);
  }
}
