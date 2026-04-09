import 'dart:async';

import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../user_management/user_repository.dart';

typedef RoomCheckDate = ({int year, int month, int day});

class RoomCheckSlot {
  final int? rcid;
  final RoomCheckDate date;
  final String roomName;
  final TaskFrequency frequency;
  User? assigned;

  RoomCheckSlot({
    required this.rcid,
    required this.date,
    required this.roomName,
    required this.frequency,
    required this.assigned,
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
  final Map<RoomCheckDate, Map<String, RoomCheckSlot>> _roomChecks = {};
  final _stateController =
  StreamController<
      Map<RoomCheckDate, Map<String, RoomCheckSlot>>
  >.broadcast();

  RoomCheckRepository({required Database database}) : _database = database {
    database.subscribeToRoomChecks((PostgresChangePayload p) {
      var p1 = p;
    });
  }

  Future<void> loadRoomChecks() async {
    final roomChecks = await _database.getRoomCheckSlots();
    print(roomChecks);
    for(var map in roomChecks){

    }
  }

  void assignListenerToRoomCheck(RoomCheckSlot roomCheckSlot) {
    // TODO
  }

}
