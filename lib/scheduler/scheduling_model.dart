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

  final Map<RoomCheckDate, Map<String, RoomCheckSlot>> _dailyInternal = {};
  final Map<RoomCheckDate, Map<String, RoomCheckSlot>> _weeklyInternal = {};
  final Map<RoomCheckDate, Map<String, RoomCheckSlot>> _monthlyInternal = {};

  late UnmodifiableMapView<RoomCheckDate, Map<String, RoomCheckSlot>>
  dailyRoomChecks;
  late UnmodifiableMapView<RoomCheckDate, Map<String, RoomCheckSlot>>
  monthlyRoomChecks;
  late UnmodifiableMapView<RoomCheckDate, Map<String, RoomCheckSlot>>
  weeklyRoomChecks;

  late Map<
    TaskFrequency,
    UnmodifiableMapView<RoomCheckDate, Map<String, RoomCheckSlot>>
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
        final date = entry.key;
        final frequencyToRoomToRoomCheck = entry.value;
        for (var MapEntry(key: frequency, value: roomToroomCheck)
            in frequencyToRoomToRoomCheck.entries) {
          for (var MapEntry(key: room, value: roomCheck)
              in roomToroomCheck.entries) {
            switch (frequency) {
              case TaskFrequency.daily:
                if (!_dailyInternal.containsKey(date)) {
                  _dailyInternal[date] = {};
                }
                _dailyInternal[date]![room] = roomCheck;
                break;
              case TaskFrequency.weekly:
                if (!_weeklyInternal.containsKey(date)) {
                  _weeklyInternal[date] = {};
                }
                _weeklyInternal[date]![room] = roomCheck;
                break;
              case TaskFrequency.monthly:
                if (!_monthlyInternal.containsKey(date)) {
                  _monthlyInternal[date] = {};
                }
                _monthlyInternal[date]![room] = roomCheck;
            }
          }
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

  UnmodifiableListView<RoomCheckSlot> getRoomChecks(
    RoomCheckDate date,
    TaskFrequency frequency,
  ) {
    final roomChecks = _frequencyToRoomChecks[frequency]?[date]?.keys;
    return UnmodifiableListView(roomChecks?.cast<RoomCheckSlot>() ?? []);
  }

  RoomCheckSlot? getRoomCheck(
    RoomCheckDate date,
    TaskFrequency frequency,
    String roomName,
  ) {
    return _frequencyToRoomChecks[frequency]?[date]?[roomName];
  }

  String? getUserAssignedToRoom(
    RoomCheckDate date,
    String roomName,
    TaskFrequency frequency,
  ) {
    return _frequencyToRoomChecks[frequency]?[date]?[roomName]?.assigned;
  }

  void assignUserToRoomCheck(
    RoomCheckDate date,
    Room room,
    User user,
    TaskFrequency frequency,
  ) {
    var roomCheck = _frequencyToRoomChecks[frequency]?[date]?[room.name];
    roomCheck ??= RoomCheckSlot(
      rcid: null,
      date: date,
      rid: room.rid,
      roomName: room.name,
      frequency: frequency,
      uid: user.uid,
      assigned: user.email,
      comment: null,
      state: RoomCheckState.notStarted,
    );
    _roomCheckRepository.assignUserToRoomCheck(roomCheck);
    notifyListeners();
  }

  void refreshData() {
    _taskListRepository.loadTaskLists();
    _roomCheckRepository.loadRoomChecks();
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
