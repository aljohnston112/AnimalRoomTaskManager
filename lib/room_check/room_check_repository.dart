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
}

class RoomCheckRepository extends ChangeNotifier {
  final Database _database;

  final Map<RoomCheckDate, Map<TaskFrequency, Map<String, RoomCheckSlot>>>
  _roomChecks = {};

  final ValueNotifier<
    Map<RoomCheckDate, Map<TaskFrequency, Map<String, RoomCheckSlot>>>
  >
  roomChecksNotifier = ValueNotifier({});

  RoomCheckRepository({required Database database}) : _database = database {
    database.subscribeToRoomChecks((PostgresChangePayload p) {
      var p1 = p;
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

      // TODO concurrency issues?
      TaskFrequency frequency = (map['frequency'] as String).toTaskFrequency;
      if (!_roomChecks[roomCheckDate]!.containsKey(frequency)) {
        _roomChecks[roomCheckDate]![frequency] = {};
      }

      var roomName = map['room_name'];
      _roomChecks[roomCheckDate]![frequency]![roomName] = RoomCheckSlot(
        rcid: map['rc_id'],
        rid: map['r_id'],
        date: roomCheckDate,
        roomName: roomName,
        frequency: frequency,
        comment: map['comment'],
        uid: map['u_id'],
        assigned: map['name'],
        state: (map['state'] as String).toRoomCheckState,
      );
    }
    roomChecksNotifier.value = _roomChecks;
  }

  void assignUserToRoomCheck(RoomCheckSlot roomCheckSlot, String user) {
    _database.assignUserToRoomCheck(roomCheckSlot, user);
  }
}
