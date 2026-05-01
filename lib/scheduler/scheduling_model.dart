import 'dart:collection';

import 'package:animal_room_task_manager/room_check/record_repository.dart';
import 'package:animal_room_task_manager/room_check/room_check_repository.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:flutter/foundation.dart';

import '../user_management/user_repository.dart';

class Room {
  final int rid;
  final String name;

  Room({required this.rid, required this.name});

  @override
  bool operator ==(Object other) => other is Room && rid == other.rid;

  @override
  int get hashCode => rid.hashCode;
}

class TaskListState {
  final bool tasksDone;
  final User? doneBy;

  TaskListState({required this.tasksDone, required this.doneBy});
}

class SchedulingModel extends ChangeNotifier {
  final RecordRepository _recordRepository;
  final RoomCheckRepository _roomCheckRepository;
  final TaskListRepository _taskListRepository;

  final Map<String, Map<RoomCheckDate, Map<Room, RoomCheckSlot>>>
  _dailyInternal = {};
  final Map<String, Map<RoomCheckDate, Map<Room, RoomCheckSlot>>>
  _weeklyInternal = {};
  final Map<String, Map<RoomCheckDate, Map<Room, RoomCheckSlot>>>
  _monthlyInternal = {};

  late UnmodifiableMapView<String, Map<RoomCheckDate, Map<Room, RoomCheckSlot>>>
  dailyRoomChecks;
  late UnmodifiableMapView<String, Map<RoomCheckDate, Map<Room, RoomCheckSlot>>>
  monthlyRoomChecks;
  late UnmodifiableMapView<String, Map<RoomCheckDate, Map<Room, RoomCheckSlot>>>
  weeklyRoomChecks;

  late Map<
    TaskFrequency,
    UnmodifiableMapView<String, Map<RoomCheckDate, Map<Room, RoomCheckSlot>>>
  >
  _frequencyToRoomChecks;

  SchedulingModel({
    required RecordRepository recordRepository,
    required RoomCheckRepository roomCheckRepository,
    required TaskListRepository taskListRepository,
  }) : _recordRepository = recordRepository,
       _roomCheckRepository = roomCheckRepository,
       _taskListRepository = taskListRepository {
    _roomCheckRepository.loadRoomChecks();
    _taskListRepository.loadTaskLists();
    updateViews();
    // TODO only the changed/new rows should be updated
    roomCheckRepository.roomChecksNotifier.addListener(() {
      final roomChecks = roomCheckRepository.roomChecksNotifier.value;
      for (final entry in roomChecks.entries) {
        final key = entry.key;
        final roomCheck = entry.value;
        var buildingName = key.buildingName;
        var date = key.date;
        var room = key.room;
        switch (key.frequency) {
          case TaskFrequency.daily:
            if (!_dailyInternal.containsKey(buildingName)) {
              _dailyInternal[buildingName] = {};
            }
            if (!_dailyInternal[buildingName]!.containsKey(date)) {
              _dailyInternal[buildingName]![date] = {};
            }
            _dailyInternal[buildingName]![date]![room] = roomCheck;
            break;
          case TaskFrequency.weekly:
            if (!_weeklyInternal.containsKey(buildingName)) {
              _weeklyInternal[buildingName] = {};
            }
            if (!_weeklyInternal[buildingName]!.containsKey(date)) {
              _weeklyInternal[buildingName]![date] = {};
            }
            _weeklyInternal[buildingName]![date]![room] = roomCheck;
            break;
          case TaskFrequency.monthly:
            if (!_monthlyInternal.containsKey(buildingName)) {
              _monthlyInternal[buildingName] = {};
            }
            if (!_monthlyInternal[buildingName]!.containsKey(date)) {
              _monthlyInternal[buildingName]![date] = {};
            }
            _monthlyInternal[buildingName]![date]![room] = roomCheck;
        }
      }
      updateViews();
      notifyListeners();
    });
  }

  void updateViews() {
    dailyRoomChecks = UnmodifiableMapView(_dailyInternal);
    weeklyRoomChecks = UnmodifiableMapView(_weeklyInternal);
    monthlyRoomChecks = UnmodifiableMapView(_monthlyInternal);
    _frequencyToRoomChecks = {
      TaskFrequency.daily: dailyRoomChecks,
      TaskFrequency.weekly: weeklyRoomChecks,
      TaskFrequency.monthly: monthlyRoomChecks,
    };
  }

  RoomCheckSlot? getRoomCheck(
    String buildingName,
    RoomCheckDate date,
    TaskFrequency frequency,
    Room room,
  ) {
    return _frequencyToRoomChecks[frequency]?[buildingName]?[date]?[room];
  }

  String? getUserAssignedToRoom(
    String buildingName,
    RoomCheckDate date,
    Room room,
    TaskFrequency frequency,
  ) {
    return getRoomCheck(buildingName, date, frequency, room)?.user?.email;
  }

  void assignUserToRoomCheck(
    String buildingName,
    RoomCheckDate date,
    Room room,
    User user,
    TaskFrequency frequency,
  ) {
    var roomCheck = getRoomCheck(buildingName, date, frequency, room);
    if (roomCheck == null) {
      roomCheck = RoomCheckSlot(
        rcid: null,
        date: date,
        room: room,
        frequency: frequency,
        user: user,
        comment: null,
        state: RoomCheckState.notStarted,
      );
    } else {
      roomCheck = roomCheck.withUser(user);
    }
    _roomCheckRepository.upsertRoomCheck(roomCheck!);
    notifyListeners();
  }

  Future<void> refreshData() async {
    await _taskListRepository.loadTaskLists();
    await _recordRepository.loadRecords();
    await _roomCheckRepository.loadRoomChecks();
  }

  TaskListState getTaskListState(
    TaskList taskList,
    Room room,
    RoomCheckDate date,
  ) {
    var recordMap = _recordRepository.getRecordsForRoom(
      room,
      date,
      taskList.frequency,
    );

    // TODO list<User>
    User? doneBy;
    if (recordMap.isNotEmpty) {
      doneBy = recordMap.values.first.doneBy;
    }

    return TaskListState(
      tasksDone: taskList.tasks.every((t) => recordMap.keys.contains(t)),
      doneBy: doneBy,
    );
  }
}
