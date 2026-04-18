import 'dart:collection';

import 'package:animal_room_task_manager/room_check/room_check_repository.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:flutter/foundation.dart';

import '../user_management/user_repository.dart';

class Room {
  final int rid;
  final String name;

  Room({required this.rid, required this.name});
}

class SchedulingModel extends ChangeNotifier {
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
    required RoomCheckRepository roomCheckRepository,
    required TaskListRepository taskListRepository,
  }) : _roomCheckRepository = roomCheckRepository,
       _taskListRepository = taskListRepository {
    updateViews();
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
        updateViews();
        notifyListeners();
      }
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
    _roomCheckRepository.assignUserToRoomCheck(roomCheck, user.email);
    notifyListeners();
  }

  void refreshData() {
    _taskListRepository.loadTaskLists();
    _roomCheckRepository.loadRoomChecks();
  }
}
