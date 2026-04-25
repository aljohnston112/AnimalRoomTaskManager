import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Building {
  final int bid;
  final String name;

  Building({required this.bid, required this.name});

  @override
  bool operator ==(Object other) => other is Building && other.bid == bid;

  @override
  int get hashCode => bid.hashCode;
}

class BuildingRepository {
  final Database _database;
  final Set<Building> _buildings = {};
  final ValueNotifier<Set<Building>> buildings = ValueNotifier({});

  BuildingRepository({required Database database}) : _database = database {
    _database.subscribeToBuildings((PostgresChangePayload p) {
      var newRecord = p.newRecord;
      if (newRecord.isNotEmpty) {
        var building = _parseBuilding(newRecord);
        _buildings.remove(building);
        if (!newRecord['deleted']) {
          _buildings.add(building);
        }
        buildings.value = Set.from(_buildings);
      }
    });
  }

  Building _parseBuilding(PostgrestMap facility) {
    return Building(bid: facility['b_id'], name: facility['name']);
  }

  Future<void> loadBuildings() async {
    final result = await _database.getBuildings();
    for (final buildingDB in result) {
      Building building = _parseBuilding(buildingDB);
      if (!buildingDB['deleted']) {
        _buildings.add(building);
      }
    }
    buildings.value = Set.from(_buildings);
  }

  Future<void> addBuilding(String buildingName) {
    return _database.insertBuilding(buildingName);
  }

  Future<void> deleteFacility(Building building) async {
    await _database.deleteBuilding(building);
  }

  Future<void> undeleteBuilding(String buildingName) async {
    await _database.undeleteBuilding(buildingName);
  }
}
