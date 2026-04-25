import 'dart:async';

import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestMap, PostgresChangePayload;

import '../scheduler/scheduling_model.dart';
import '../user_management/user_repository.dart';

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
  final User? user;

  RoomCheckSlot({
    required this.rcid,
    required this.date,
    required this.room,
    required this.frequency,
    required this.comment,
    required this.user,
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
      user: user,
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
      user: user,
      state: RoomCheckState.started,
    );
  }

  RoomCheckSlot? withUser(User user) {
    return RoomCheckSlot(
      rcid: rcid,
      date: date,
      room: room,
      frequency: frequency,
      comment: comment,
      user: user,
      state: RoomCheckState.started,
    );
  }
}

class RoomCheckRepository {
  final Database _database;

  final Map<RoomCheckSlotKey, RoomCheckSlot> _roomChecks = {};

  final ValueNotifier<Map<RoomCheckSlotKey, RoomCheckSlot>> roomChecksNotifier =
      ValueNotifier({});

  RoomCheckRepository({required Database database}) : _database = database {
    database.subscribeToRoomChecks((PostgresChangePayload p) async {
      var map = p.newRecord;
      // These can be batched if users think app is slow
      var rcid = map['rc_id'];
      final updatedRow = await database.getRoomCheckWithId(rcid);
      DateTime parsedDate = DateTime.parse(map['date_time']);
      RoomCheckDate roomCheckDate = (
        year: parsedDate.year,
        month: parsedDate.month,
        day: parsedDate.day,
      );
      User? user;
      var uid = updatedRow['u_id'];
      if (uid != null) {
        user = User(
          email: updatedRow['user_name'],
          group: UserGroup.values[updatedRow['ug_id']],
          uid: uid,
        );
      }
      RoomCheckSlot roomCheck = RoomCheckSlot(
        rcid: rcid,
        date: roomCheckDate,
        room: Room(rid: updatedRow['r_id'], name: updatedRow['room_name']),
        frequency: (updatedRow['frequency'] as String).toTaskFrequency,
        comment: updatedRow['comment'],
        user: user,
        state: (updatedRow['state'] as String).toRoomCheckState,
      );
      RoomCheckSlotKey key = RoomCheckSlotKey(
        buildingName: updatedRow['building_name'],
        room: roomCheck.room,
        date: roomCheckDate,
        frequency: roomCheck.frequency,
      );
      _roomChecks[key] = roomCheck;
      roomChecksNotifier.value = Map.from(_roomChecks);
    });
  }

  Future<void> loadRoomChecks() async {
    final buildingRoomChecksList = await _database.getRoomCheckSlots();
    for (var buildingRoomCheckMap in buildingRoomChecksList) {
      final bid = buildingRoomCheckMap['b_id'];
      final buildingName = buildingRoomCheckMap['building_name'];
      final roomChecksByFrequencyDB =
          buildingRoomCheckMap['room_checks_by_frequency'];
      for (final roomChecksByFrequency in roomChecksByFrequencyDB) {
        final frequency =
            (roomChecksByFrequency['frequency'] as String).toTaskFrequency;
        final roomChecksByDateDB = roomChecksByFrequency['dates'];
        for (final roomChecksByDate in roomChecksByDateDB) {
          DateTime parsedDate = DateTime.parse(roomChecksByDate['date_time']);
          RoomCheckDate roomCheckDate = (
            year: parsedDate.year,
            month: parsedDate.month,
            day: parsedDate.day,
          );
          final roomCheckSlotsDB = roomChecksByDate['slots'];
          for (var roomCheckMap in roomCheckSlotsDB) {
            RoomCheckSlot roomCheck = _parseRoomCheck(
              roomCheckMap,
              roomCheckDate,
              frequency,
            );
            RoomCheckSlotKey key = RoomCheckSlotKey(
              buildingName: buildingName,
              room: roomCheck.room,
              date: roomCheckDate,
              frequency: roomCheck.frequency,
            );
            _roomChecks[key] = roomCheck;
          }
        }
      }
    }
    roomChecksNotifier.value = Map.from(_roomChecks);
  }

  RoomCheckSlot _parseRoomCheck(
    PostgrestMap map,
    RoomCheckDate date,
    TaskFrequency frequency,
  ) {
    final roomCheck = RoomCheckSlot(
      rcid: map['rc_id'],
      date: date,
      room: Room(rid: map['r_id'], name: map['room_name']),
      frequency: frequency,
      comment: map['comment'],
      user: User(
        email: map['user_name'],
        group: UserGroup.values[map['ug_id']],
        uid: map['user_id'],
      ),
      state: (map['state'] as String).toRoomCheckState,
    );
    return roomCheck;
  }

  void assignUserToRoomCheck(RoomCheckSlot roomCheckSlot) {
    _database.upsertRoomCheckAndGetRcid(roomCheckSlot);
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
    upsertRoomCheck(withComment);
  }

  Future<int> upsertRoomCheck(RoomCheckSlot roomCheckSlot) async {
    return await _database.upsertRoomCheckAndGetRcid(roomCheckSlot);
  }
}
