import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Facility {
  final int fid;
  final String name;

  Facility({required this.fid, required this.name});

  @override
  bool operator ==(Object other) => other is Facility && other.fid == fid;

  @override
  int get hashCode => fid.hashCode;
}

class FacilityRepository extends ChangeNotifier {
  final Database _database;
  final Set<Facility> _facilities = {};
  final ValueNotifier<Set<Facility>> facilities = ValueNotifier({});

  FacilityRepository({required Database database}) : _database = database {
    _database.subscribeToFacilities((PostgresChangePayload p) {
      var newRecord = p.newRecord;
      var facility = _parseFacility(newRecord);
      _facilities.remove(facility);
      if (!newRecord['deleted']) {
        _facilities.add(facility);
      }
      facilities.value = Set.from(_facilities);
    });
  }

  Facility _parseFacility(PostgrestMap facility) {
    return Facility(fid: facility['f_id'], name: facility['name']);
  }

  Future<void> loadFacilities() async {
    final result = await _database.getFacilities();
    for (final facilityDB in result) {
      Facility facility = _parseFacility(facilityDB);
      if(!facilityDB['deleted']) {
        _facilities.add(facility);
      }
    }
    facilities.value = Set.from(_facilities);
  }

  Future<void> addFacility(String facilityName) {
    return _database.insertFacility(facilityName);
  }

  Future<void> deleteFacility(Facility facility) async {
    await _database.deleteFacility(facility);
  }

  Future<void> undeleteFacility(String facilityName) async {
    await _database.undeleteFacility(facilityName);
  }
}
