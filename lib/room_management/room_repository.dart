import 'package:animal_room_task_manager/scheduler/scheduling_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_client/database.dart';

class RoomModel {
  final int rid;
  final String roomName;
  final int bid;
  final int fid;
  final int lid;
  final List<int> tlids;

  RoomModel({
    required this.rid,
    required this.roomName,
    required this.bid,
    required this.fid,
    required this.lid,
    required this.tlids,
  });

  @override
  bool operator ==(Object other) => other is RoomModel && rid == other.rid;

  @override
  int get hashCode => rid.hashCode;

  Room toRoom() {
    return Room(rid: rid, name: roomName);
  }

  @override
  String toString() {
    return rid.toString();
  }
}

class RoomRepository {
  final Database _database;
  final Set<RoomModel> _rooms = {};
  final ValueNotifier<Set<RoomModel>> rooms = ValueNotifier({});

  RoomRepository({required Database database}) : _database = database {
    _database.subscribeToFullRooms((data) {
      final payload = data['payload'];
      var room = _parseRoom(payload);
      _rooms.remove(room);
      if (!payload['room']['deleted']) {
        _rooms.add(room);
      }
      rooms.value = Set.from(_rooms);
    });
    _database.subscribeToRoomsUpdates((data) {
      bool? deleted = data.newRecord['deleted'];
      if (deleted == true) {
        _rooms.removeWhere((r) => r.rid == data.newRecord['r_id']);
      } else {
        // TODO can do a call to get just the one
        loadRooms();
      }
      rooms.value = Set.from(_rooms);
    });
  }

  RoomModel _parseRoom(PostgrestMap payload) {
    final room = payload['room'];
    final tlids = payload['tl_ids'] ?? [];
    return RoomModel(
      rid: room['r_id'],
      roomName: room['name'],
      bid: room['b_id'],
      fid: room['f_id'],
      lid: room['l_id'],
      tlids: List<int>.from(tlids),
    );
  }

  Future<void> loadRooms() async {
    final result = await _database.getRooms();
    for (final roomDB in result) {
      RoomModel room = _parseRoom(roomDB);
      if (!roomDB['room']['deleted']) {
        _rooms.add(room);
      }
    }
    rooms.value = Set.from(_rooms);
  }

  Future<void> addRoom({
    required String roomName,
    required int lid,
    required int fid,
    required int bid,
    required List<int> tlids,
  }) {
    return _database.insertRoom(
      roomName: roomName,
      lid: lid,
      fid: fid,
      bid: bid,
      tlids: tlids,
    );
  }

  Future<void> deleteRoom(RoomModel room) async {
    await _database.deleteRoom(room.rid);
  }

  Future<void> undeleteRoom(String roomName) async {
    await _database.undeleteRoom(roomName);
  }

  Future<void> updateRoom({
    required int rid,
    required int lid,
    required List<int> tlids,
  }) async {
    await _database.updateRoom(rid: rid, lid: lid, tlids: tlids);
  }
}
