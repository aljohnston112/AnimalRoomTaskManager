import 'dart:async';

import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../scheduler/scheduling_model.dart';

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

class RoomCheckSlotKey {
  final String buildingName;
  final Room room;
  final RoomCheckDate date;
  final TaskFrequency frequency;

  RoomCheckSlotKey({
    required this.buildingName,
    required this.room,
    required this.date,
    required this.frequency,
  });

  @override
  bool operator ==(Object other) {
    return other is RoomCheckSlotKey &&
        other.buildingName == buildingName &&
        other.room == room &&
        other.date == date &&
        other.frequency == frequency;
  }

  @override
  int get hashCode => Object.hash(
    buildingName.hashCode,
    room.hashCode,
    date.hashCode,
    frequency.hashCode,
  );
}

class RoomCheckSlot {
  final int? rcid;
  final RoomCheckDate date;
  final Room room;
  final RoomCheckState state;
  final TaskFrequency frequency;
  final String? comment;
  final int? uid;
  String? assigned;

  RoomCheckSlot({
    required this.rcid,
    required this.date,
    required this.room,
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
        other.room == room &&
        other.frequency == frequency;
  }

  @override
  int get hashCode => date.hashCode ^ room.hashCode;

  RoomCheckSlot withComment(String comment) {
    return RoomCheckSlot(
      rcid: rcid,
      date: date,
      room: room,
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
      room: room,
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

  final Map<RoomCheckSlotKey, RoomCheckSlot> _roomChecks = {};

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
      print(roomCheck);
      //   if (!_roomChecks.containsKey(roomCheck.date)) {
      //     _roomChecks[roomCheck.date] = {};
      //   }
      //   if (!_roomChecks[roomCheck.date]!.containsKey(roomCheck.frequency)) {
      //     _roomChecks[roomCheck.date]![roomCheck.frequency] = {};
      //   }
      //   _roomChecks[roomCheck.date]![roomCheck.frequency]![roomCheck.roomName] =
      //       roomCheck;
      //   roomChecksNotifier.value = Map.from(_roomChecks);
    });
  }

  Future<void> loadRoomChecks() async {
    final buildingRoomChecksList = await _database.getRoomCheckSlots();
    for (var buildingRoomCheckMap in buildingRoomChecksList) {
      final bid = buildingRoomCheckMap['b_id'];
      final buildingName = buildingRoomCheckMap['building_name'];
      final roomChecksList = buildingRoomCheckMap['room_check_slots'];
      for (var roomCheckMap in roomChecksList) {
        DateTime parsedDate = DateTime.parse(roomCheckMap['date_time']);
        RoomCheckDate roomCheckDate = (
          year: parsedDate.year,
          month: parsedDate.month,
          day: parsedDate.day,
        );
        RoomCheckSlot roomCheck = _parseRoomCheck(roomCheckMap);
        print(roomCheck);
        RoomCheckSlotKey key = RoomCheckSlotKey(
          buildingName: buildingName,
          room: roomCheck.room,
          date: roomCheckDate,
          frequency: roomCheck.frequency,
        );
        _roomChecks[key] = roomCheck;
      }
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
      date: roomCheckDate,
      room: Room(rid: map['r_id'], name: map['room_name']),
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
    String buildingName,
    RoomCheckDate date,
    TaskFrequency frequency,
    Room room,
  ) {
    RoomCheckSlotKey key = RoomCheckSlotKey(
      buildingName: buildingName,
      room: room,
      date: date,
      frequency: frequency,
    );
    return _roomChecks[key];
  }

  void saveComment(
    String buildingName,
    RoomCheckSlot roomCheckSlot,
    String comment,
  ) {
    // The room check in the map wil be more recent
    RoomCheckSlotKey key = RoomCheckSlotKey(
      buildingName: buildingName,
      room: roomCheckSlot.room,
      date: roomCheckSlot.date,
      frequency: roomCheckSlot.frequency,
    );
    var withComment = _roomChecks[key]?.withComment(comment);

    // Will use the provided room check since if it is new
    withComment ??= roomCheckSlot.withComment(comment);
    updateRoomCheck(withComment);
  }

  void updateRoomCheck(RoomCheckSlot roomCheckSlot) {
    _database.upsertRoomCheck(roomCheckSlot);
  }
}
