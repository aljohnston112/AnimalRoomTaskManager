import 'dart:collection';

import 'package:animal_room_task_manager/room_check/room_check_repository.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:flutter/foundation.dart';

import '../user_management/user_repository.dart';

class SchedulingModel extends ChangeNotifier {
  final RoomCheckRepository _roomCheckRepository;

  final Map<RoomCheckDate, Map<String, RoomCheckSlot>> _dailyInternal = {};
  final Map<RoomCheckDate, Map<String, RoomCheckSlot>> _weeklyInternal = {};
  final Map<RoomCheckDate, Map<String, RoomCheckSlot>> _monthlyInternal = {};

  late final UnmodifiableMapView<RoomCheckDate, Map<String, RoomCheckSlot>>
  dailyRoomChecks;
  late final UnmodifiableMapView<RoomCheckDate, Map<String, RoomCheckSlot>>
  monthlyRoomChecks;
  late final UnmodifiableMapView<RoomCheckDate, Map<String, RoomCheckSlot>>
  weeklyRoomChecks;

  late final _frequencyToRoomChecks = {
    TaskFrequency.daily: dailyRoomChecks,
    TaskFrequency.weekly: weeklyRoomChecks,
    TaskFrequency.monthly: monthlyRoomChecks,
  };

  SchedulingModel({required RoomCheckRepository roomCheckRepository})
    : _roomCheckRepository = roomCheckRepository {
    dailyRoomChecks = UnmodifiableMapView(_dailyInternal);
    weeklyRoomChecks = UnmodifiableMapView(_weeklyInternal);
    monthlyRoomChecks = UnmodifiableMapView(_monthlyInternal);
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
    String roomName,
    User user,
    TaskFrequency frequency,
  ) {
    var roomCheckSlot = RoomCheckSlot(
      rcid: null,
      date: date,
      roomName: roomName,
      frequency: frequency,
      assigned: user.email,
      comment: null,
      state: RoomCheckState.notStarted
    );
    _roomCheckRepository.assignListenerToRoomCheck(roomCheckSlot);
    notifyListeners();
  }

  void loadRoomChecks() {
    _roomCheckRepository.loadRoomChecks();
  }
}
