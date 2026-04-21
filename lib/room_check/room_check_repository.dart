import 'dart:async';

import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

typedef RoomCheckDate = ({int year, int month, int day});

extension RoomCheckDateSupabase on RoomCheckDate {
  String toSupabaseString() {
    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

enum RoomCheckState { notStarted, started, done }

extension RoomCheckStateExtension on RoomCheckState {
  String get toDbString {
    switch (this) {
      case RoomCheckState.notStarted:
        return 'not_started';
      case RoomCheckState.started:
        return 'started';
      case RoomCheckState.done:
        return 'done';
    }
  }
}

extension RoomCheckStateParser on String {
  RoomCheckState get toRoomCheckState {
    switch (this) {
      case 'not_started':
        return RoomCheckState.notStarted;
      case 'started':
        return RoomCheckState.started;
      case 'done':
        return RoomCheckState.done;
      default:
        throw ArgumentError('Invalid RoomCheckState string: $this');
    }
  }
}

class RoomCheckSlot {
  final int? rcid;
  final RoomCheckDate date;
  final int rid;
  final String roomName;
  final RoomCheckState state;
  final TaskFrequency frequency;
  final String? comment;
  final int? uid;
  String? assigned;

  RoomCheckSlot({
    required this.rcid,
    required this.date,
    required this.rid,
    required this.roomName,
    required this.frequency,
    required this.comment,
    required this.uid,
    required this.assigned,
    required this.state,
  });

  @override
  bool operator ==(Object other) {
    return other is RoomCheckSlot &&
        other.date == date &&
        other.roomName == roomName &&
        other.frequency == frequency;
  }

  @override
  int get hashCode => date.hashCode ^ roomName.hashCode;

  RoomCheckSlot withComment(String comment) {
    return RoomCheckSlot(
      rcid: rcid,
      date: date,
      rid: rid,
      roomName: roomName,
      frequency: frequency,
      comment: comment,
      uid: uid,
      assigned: assigned,
      state: state,
    );
  }

  RoomCheckSlot withState(RoomCheckState started) {
    return RoomCheckSlot(
      rcid: rcid,
      date: date,
      rid: rid,
      roomName: roomName,
      frequency: frequency,
      comment: comment,
      uid: uid,
      assigned: assigned,
      state: RoomCheckState.started,
    );
  }
}

class RoomCheckRepository {
  final Database _database;

  final Map<RoomCheckDate, Map<TaskFrequency, Map<String, RoomCheckSlot>>>
  _roomChecks = {};

  final ValueNotifier<
    Map<RoomCheckDate, Map<TaskFrequency, Map<String, RoomCheckSlot>>>
  >
  roomChecksNotifier = ValueNotifier({});

  RoomCheckRepository({required Database database}) : _database = database {
    database.subscribeToRoomChecks((PostgresChangePayload p) async {
      var map = p.newRecord;
      // These can be batched if users think app is slow
      final updatedRow = await database.getRoomCheckWithId(map['rc_id']);
      RoomCheckSlot roomCheck = _parseRoomCheck(updatedRow);
      if (!_roomChecks.containsKey(roomCheck.date)) {
        _roomChecks[roomCheck.date] = {};
      }
      if (!_roomChecks[roomCheck.date]!.containsKey(roomCheck.frequency)) {
        _roomChecks[roomCheck.date]![roomCheck.frequency] = {};
      }
      _roomChecks[roomCheck.date]![roomCheck.frequency]![roomCheck.roomName] =
          roomCheck;
      roomChecksNotifier.value = Map.from(_roomChecks);
    });
  }

  Future<void> loadRoomChecks() async {
    final roomChecks = await _database.getRoomCheckSlots();
    List<RoomCheckDate> dates = _roomChecks.keys.toList();
    for (var map in roomChecks) {
      DateTime parsedDate = DateTime.parse(map['date_time']);
      RoomCheckDate roomCheckDate = (
        year: parsedDate.year,
        month: parsedDate.month,
        day: parsedDate.day,
      );
      if (!dates.contains(roomCheckDate)) {
        _roomChecks[roomCheckDate] = {};
        dates.add(roomCheckDate);
      }
      RoomCheckSlot roomCheck = _parseRoomCheck(map);
      if (!_roomChecks[roomCheck.date]!.containsKey(roomCheck.frequency)) {
        _roomChecks[roomCheck.date]![roomCheck.frequency] = {};
      }
      _roomChecks[roomCheck.date]![roomCheck.frequency]![roomCheck.roomName] =
          roomCheck;
    }
    roomChecksNotifier.value = Map.from(_roomChecks);
  }

  RoomCheckSlot _parseRoomCheck(PostgrestMap map) {
    DateTime parsedDate = DateTime.parse(map['date_time']);
    RoomCheckDate roomCheckDate = (
      year: parsedDate.year,
      month: parsedDate.month,
      day: parsedDate.day,
    );
    final roomCheck = RoomCheckSlot(
      rcid: map['rc_id'],
      rid: map['r_id'],
      date: roomCheckDate,
      roomName: map['room_name'],
      frequency: (map['frequency'] as String).toTaskFrequency,
      comment: map['comment'],
      uid: map['u_id'],
      assigned: map['name'],
      state: (map['state'] as String).toRoomCheckState,
    );
    return roomCheck;
  }

  void assignUserToRoomCheck(RoomCheckSlot roomCheckSlot) {
    _database.assignUserToRoomCheck(roomCheckSlot);
  }

  RoomCheckSlot? getRoomCheck(
    RoomCheckDate date,
    TaskFrequency frequency,
    String roomName,
  ) {
    if (_roomChecks.containsKey(date)) {
      var frequencyToRoomChecks = _roomChecks[date];
      if (frequencyToRoomChecks?.containsKey(frequency) == true) {
        if (frequencyToRoomChecks?[frequency]?.containsKey(roomName) == true) {
          return frequencyToRoomChecks?[frequency]?[roomName];
        }
      }
    }
    return null;
  }

  void saveComment(RoomCheckSlot roomCheckSlot, String comment) {
    var date = roomCheckSlot.date;
    if (!_roomChecks.containsKey(date)) {
      _roomChecks[date] = {};
    }
    var frequencyToRoomChecks = _roomChecks[date];
    var frequency = roomCheckSlot.frequency;
    if (frequencyToRoomChecks?.containsKey(frequency) != true) {
      frequencyToRoomChecks?[frequency] = {};
    }
    var roomName = roomCheckSlot.roomName;
    var withComment =
    frequencyToRoomChecks?[frequency]?[roomName]?.withComment(comment);
    withComment ??= roomCheckSlot.withComment(comment);
    updateRoomCheck(withComment);
  }

  void updateRoomCheck(RoomCheckSlot roomCheckSlot) {
    _database.upsertRoomCheck(roomCheckSlot);
  }
}
