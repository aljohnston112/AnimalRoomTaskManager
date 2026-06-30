import 'dart:collection';

import 'package:animal_room_task_manager/query/query_model.dart';
import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Building implements Comparable<Building> {
  final int bid;
  final String name;

  Building({required this.bid, required this.name});

  @override
  bool operator ==(Object other) => other is Building && other.bid == bid;

  @override
  int get hashCode => bid.hashCode;

  @override
  int compareTo(Building other) {
    return name.compareTo(other.name);
  }
}

class BuildingRepository {
  final Database _database;
  final _buildings = SplayTreeSet<Building>();
  late final _buildingsNotifier = RefreshableNotifier<Set<Building>>(
    _buildings,
  );
  late final ValueListenable<Set<Building>> buildingsListenable =
      _buildingsNotifier;

  BuildingRepository({required Database database}) : _database = database {
    _database.subscribeToBuildings((PostgresChangePayload p) {
      var newRecord = p.newRecord;
      if (newRecord.isNotEmpty) {
        var building = _parseBuilding(newRecord);
        _buildings.remove(building);
        if (!newRecord['deleted']) {
          _buildings.add(building);
        }
        _buildingsNotifier.refresh();
      }
    });
  }

  Building _parseBuilding(PostgrestMap building) {
    return Building(bid: building['b_id'], name: building['name']);
  }

  Future<void> loadBuildings() async {
    _buildings.clear();
    final result = await _database.getBuildings();
    for (final buildingDB in result) {
      Building building = _parseBuilding(buildingDB);
      if (!buildingDB['deleted']) {
        _buildings.add(building);
      }
    }
    _buildingsNotifier.refresh();
  }

  Future<void> addBuilding(String buildingName) {
    return _database.insertBuilding(buildingName);
  }

  Future<void> deleteBuilding(Building building) async {
    await _database.deleteBuilding(building);
  }

  Future<void> undeleteBuilding(String buildingName) async {
    await _database.undeleteBuilding(buildingName);
  }
}
