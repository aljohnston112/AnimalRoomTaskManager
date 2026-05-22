import 'dart:collection';

import 'package:animal_room_task_manager/query/query_model.dart';
import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../building_management/building_repository.dart';
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

  QuantitativeRange({
    required this.min,
    required this.max,
    required this.units,
  });

  @override
  String toString() {
    return "$min to "
        "$max "
        "$units";
  }
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

Task parseTask(PostgrestMap taskMap, [int? tid]) {
  tid ??= taskMap['t_id'];
  final taskName = taskMap['task_name'];
  final isManagerTask = taskMap['manager_only'];
  final quantitativeRangesDB = taskMap['quantitative_ranges'];
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
      );
    }
    final requiredRangeDB = quantitativeRangesDB['required_range'];
    if (requiredRangeDB != null) {
      requiredRange = QuantitativeRange(
        min: requiredRangeDB['min'],
        max: requiredRangeDB['max'],
        units: unit,
      );
    }
    return QuantitativeTask(
      description: taskName,
      managerOnly: isManagerTask,
      tid: tid!,
      warningRange: warningRange,
      requiredRange: requiredRange,
    );
  } else {
    return Task(description: taskName, managerOnly: isManagerTask, tid: tid!);
  }
}

class TaskList {
  final int tlid;
  final String name;
  final TaskFrequency frequency;
  final UnmodifiableMapView<int, Task> tasks;

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
  final Building building;
  final Room room;
  final TaskFrequency frequency;

  TaskListKey({
    required this.building,
    required this.room,
    required this.frequency,
  });

  @override
  bool operator ==(Object other) {
    return other is TaskListKey &&
        other.building == building &&
        other.room == room &&
        other.frequency == frequency;
  }

  @override
  int get hashCode => Object.hash(building, room, frequency);
}

class TaskListRepository {
  final Database _database;

  final Set<Task> _tasks = {};
  late final RefreshableNotifier<UnmodifiableSetView<Task>> _tasksRefreshable =
      RefreshableNotifier(UnmodifiableSetView(_tasks));
  late final ValueListenable<UnmodifiableSetView<Task>> tasksListenable =
      _tasksRefreshable;

  UnmodifiableSetView<Task> get tasks => tasksListenable.value;

  final Map<TaskListKey, TaskList> _taskListMap = {};
  late final RefreshableNotifier<UnmodifiableMapView<TaskListKey, TaskList>>
  _taskListMapRefreshable = RefreshableNotifier(
    UnmodifiableMapView(_taskListMap),
  );
  late final ValueListenable<UnmodifiableMapView<TaskListKey, TaskList>>
  taskListMapListenable = _taskListMapRefreshable;

  UnmodifiableMapView<TaskListKey, TaskList> get taskListMap =>
      taskListMapListenable.value;

  final Map<TaskFrequency, Set<TaskList>> _taskLists = {};
  late final RefreshableNotifier<
    UnmodifiableMapView<TaskFrequency, Set<TaskList>>
  >
  _taskListsRefreshable = RefreshableNotifier(UnmodifiableMapView(_taskLists));
  late final ValueListenable<UnmodifiableMapView<TaskFrequency, Set<TaskList>>>
  taskListsListenable = _taskListsRefreshable;

  UnmodifiableMapView<TaskFrequency, Set<TaskList>> get taskLists =>
      taskListsListenable.value;

  TaskListRepository({required Database database}) : _database = database {
    _database.subscribeToTasks((data) {
      final payload = data['payload'];
      _tasks.add(parseTask(payload));
      _tasksRefreshable.refresh();
    });

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
      final Map<int, Task> tasks = {};
      final tasksDB = payload['tasks'];
      if (tasksDB != null) {
        for (final task in tasksDB) {
          tasks[task['index']] = (parseTask(task));
        }
      }
      final taskList = TaskList(
        tlid: tlid,
        name: taskListName,
        frequency: frequency,
        tasks: UnmodifiableMapView(tasks),
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
              building: Building(bid: bid, name: buildingName),
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

            // Tasks in the task list
            Map<int, Task> tasks = {};
            final tasksDB = taskListDB['tasks'];
            if (tasksDB != null) {
              for (final taskDB in tasksDB) {
                tasks[taskDB['index']] = (parseTask(taskDB));
              }
            }
            TaskList taskList = TaskList(
              tlid: tlid,
              name: taskListName,
              frequency: frequency,
              tasks: UnmodifiableMapView(tasks),
            );

            // Rooms with the task list
            List<Room> rooms = [];
            final roomsDB = taskListDB['rooms'];
            if (roomsDB != null) {
              for (final roomDB in roomsDB) {
                rooms.add(Room(rid: roomDB['r_id'], name: roomDB['room_name']));
              }
              for (final room in rooms) {
                TaskListKey taskListKey = TaskListKey(
                  building: Building(bid: bid, name: buildingName),
                  room: room,
                  frequency: frequency,
                );
                _taskListMap.remove(taskListKey);
                _taskListMap[taskListKey] = taskList;
              }
            } else {
              unassignedTaskLists.add(taskList);
            }
          }
        }
      }
    }
    _updateTaskLists(unassignedTaskLists: unassignedTaskLists);
  }

  void _updateTaskLists({List<TaskList>? unassignedTaskLists}) {
    _taskListMapRefreshable.refresh();

    // Aggregate all the task lists
    for (final taskList in _taskListMap.values) {
      _taskLists.putIfAbsent(taskList.frequency, () => {}).add(taskList);
    }
    unassignedTaskLists ??= [];
    for (final taskList in unassignedTaskLists) {
      _taskLists.putIfAbsent(taskList.frequency, () => {});
      _taskLists[taskList.frequency]!.remove(taskList);
      _taskLists[taskList.frequency]!.add(taskList);
    }
    _taskListsRefreshable.refresh();
  }

  Future<void> loadTasks() async {
    final tasksMap = await _database.getTasks();
    for (final taskMap in tasksMap) {
      final taskMapDB = taskMap['jsonb_build_object'];
      _tasks.add(parseTask(taskMapDB));
    }
    _tasksRefreshable.refresh();
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

  bool taskDescriptionExists(String value) {
    return _tasks.any((t) => t.description == value);
  }

  Future<void> addTask(String description, bool isManagerOnly) async {
    _database.addTask(description, isManagerOnly);
  }

  Future<void> addQuantitativeTask(
    String description,
    bool isManagerOnly,
    QuantitativeRange<double>? warningRange,
    QuantitativeRange<double>? requiredRange,
  ) async {
    _database.addQuantitativeTask(
      description: description,
      isManagerOnly: isManagerOnly,
      warningRange: warningRange,
      requiredRange: requiredRange,
    );
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
}
