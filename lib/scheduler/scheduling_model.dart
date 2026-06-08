import 'dart:collection';

import 'package:animal_room_task_manager/building_management/building_repository.dart';
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
  final List<User> doneBy;

  TaskListState({required this.tasksDone, required this.doneBy});
}

class SchedulingModel extends ChangeNotifier {
  final RecordRepository _recordRepository;
  final RoomCheckRepository _roomCheckRepository;
  final TaskListRepository _taskListRepository;

  late final ValueListenable<Set<User>> usersNotifier;

  Set<User> get users => usersNotifier.value;

  final _currentBuildingNotifier = ValueNotifier<Building?>(null);
  late final ValueListenable currentBuildingListenable =
      _currentBuildingNotifier;

  Building? get currentBuilding => currentBuildingListenable.value;

  late ValueListenable taskListMapNotifier =
      _taskListRepository.taskListMapListenable;

  UnmodifiableMapView<TaskListKey, TaskList> get taskListMap =>
      taskListMapNotifier.value;

  final Map<Building, Map<RoomCheckDate, Map<Room, RoomCheckSlot>>>
  _dailyInternal = {};
  final Map<Building, Map<RoomCheckDate, Map<Room, RoomCheckSlot>>>
  _weeklyInternal = {};
  final Map<Building, Map<RoomCheckDate, Map<Room, RoomCheckSlot>>>
  _monthlyInternal = {};

  late UnmodifiableMapView<
    Building,
    Map<RoomCheckDate, Map<Room, RoomCheckSlot>>
  >
  dailyRoomChecks;
  late UnmodifiableMapView<
    Building,
    Map<RoomCheckDate, Map<Room, RoomCheckSlot>>
  >
  monthlyRoomChecks;
  late UnmodifiableMapView<
    Building,
    Map<RoomCheckDate, Map<Room, RoomCheckSlot>>
  >
  weeklyRoomChecks;

  late Map<
    TaskFrequency,
    UnmodifiableMapView<Building, Map<RoomCheckDate, Map<Room, RoomCheckSlot>>>
  >
  _frequencyToRoomChecks;

  SchedulingModel({
    required RecordRepository recordRepository,
    required RoomCheckRepository roomCheckRepository,
    required TaskListRepository taskListRepository,
    required UserRepository userRepository,
  }) : _recordRepository = recordRepository,
       _roomCheckRepository = roomCheckRepository,
       _taskListRepository = taskListRepository {
    _roomCheckRepository.loadRoomChecks();
    _taskListRepository.loadTaskLists();
    usersNotifier = userRepository.usersNotifier;
    userRepository.loadUsers();
    updateViews();
    // TODO only the changed/new rows should be updated
    roomCheckRepository.roomChecksNotifier.addListener(() {
      final roomChecks = roomCheckRepository.roomChecksNotifier.value;
      for (final entry in roomChecks.entries) {
        final key = entry.key;
        final roomCheck = entry.value;
        var buildingName = key.building;
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
    Building building,
    RoomCheckDate date,
    TaskFrequency frequency,
    Room room,
  ) {
    return _frequencyToRoomChecks[frequency]?[building]?[date]?[room];
  }

  String? getUserAssignedToRoom(
    Building building,
    RoomCheckDate date,
    Room room,
    TaskFrequency frequency,
  ) {
    return getRoomCheck(building, date, frequency, room)?.user?.email;
  }

  void assignUserToRoomCheck(
    Building building,
    RoomCheckDate date,
    Room room,
    User user,
    TaskFrequency frequency,
  ) {
    var roomCheck = getRoomCheck(building, date, frequency, room);
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

    List<User> doneBy;
    if (recordMap.isNotEmpty) {
      doneBy = recordMap.values.map((record) => record.doneBy).toList();
    } else {
      doneBy = [];
    }

    return TaskListState(
      tasksDone: taskList.tasks.values.every((t) => recordMap.keys.contains(t)),
      doneBy: doneBy,
    );
  }

  Future<void> loadRoomCheckRecords(
    Room room,
    RoomCheckDate date,
    TaskFrequency frequency,
  ) async {
    _recordRepository.loadRecordsForRoom(room, date, frequency);
  }

  void buildingClicked(Building building) {
    _currentBuildingNotifier.value = building;
  }
}
