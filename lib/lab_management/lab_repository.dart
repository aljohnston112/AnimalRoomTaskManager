import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Lab {
  final int lid;
  final String name;
  final Color color;

  Lab({required this.lid, required this.name, required this.color});

  @override
  bool operator ==(Object other) => other is Lab && other.lid == lid;

  @override
  int get hashCode => lid.hashCode;
}

class LabRepository {
  final Database _database;
  final Set<Lab> _labs = {};
  final ValueNotifier<Set<Lab>> labs = ValueNotifier({});

  LabRepository({required Database database}) : _database = database {
    _database.subscribeToLabs((PostgresChangePayload p) {
      var newRecord = p.newRecord;
      if (newRecord.isNotEmpty) {
        var lab = _parseLab(newRecord);
        _labs.remove(lab);
        if (!newRecord['deleted']) {
          _labs.add(lab);
        }
        labs.value = Set.from(_labs);
      }
    });
  }

  Lab _parseLab(PostgrestMap lab) {
    return Lab(lid: lab['l_id'], name: lab['name'], color: Color(lab['color']));
  }

  Future<void> loadLabs() async {
    final result = await _database.getLabs();
    for (final labDB in result) {
      Lab lab = _parseLab(labDB);
      if (!labDB['deleted']) {
        _labs.add(lab);
      }
    }
    labs.value = Set.from(_labs);
  }

  Future<void> addLab(String labName, int color) {
    return _database.insertLab(labName, color);
  }

  Future<void> deleteLab(Lab lab) async {
    await _database.deleteLab(lab);
  }

  Future<void> undeleteLab(String labName) async {
    await _database.undeleteLab(labName);
  }
}
