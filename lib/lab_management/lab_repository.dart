import 'dart:collection';

import 'package:animal_room_task_manager/query/query_model.dart';
import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Lab implements Comparable<Lab> {
  final int lid;
  final String name;
  final Color color;

  Lab({required this.lid, required this.name, required this.color});

  @override
  bool operator ==(Object other) => other is Lab && other.lid == lid;

  @override
  int get hashCode => lid.hashCode;

  @override
  int compareTo(Lab other) {
    return name.compareTo(other.name);
  }
}

class LabRepository {
  final Database _database;

  final _labs = SplayTreeSet<Lab>();
  late final _labsNotifier = RefreshableNotifier<Set<Lab>>(_labs);
  late final ValueListenable<Set<Lab>> labsListenable = _labsNotifier;

  LabRepository({required Database database}) : _database = database {
    _database.subscribeToLabs((PostgresChangePayload p) {
      var newRecord = p.newRecord;
      if (newRecord.isNotEmpty) {
        var lab = _parseLab(newRecord);
        _labs.remove(lab);
        if (!newRecord['deleted']) {
          _labs.add(lab);
        }
        _labsNotifier.refresh();
      }
    });
  }

  Lab _parseLab(PostgrestMap lab) {
    final int colorInt = lab['color'] as int;
    return Lab(lid: lab['l_id'], name: lab['name'], color: Color(colorInt));
  }

  Future<void> loadLabs() async {
    final result = await _database.getLabs();
    _labs.clear();
    for (final labDB in result) {
      Lab lab = _parseLab(labDB);
      if (!labDB['deleted']) {
        _labs.add(lab);
      }
    }
    _labsNotifier.refresh();
  }

  Future<void> addLab(String labName, int color) {
    return _database.insertLab(labName, color);
  }

  Future<void> deleteLab(Lab lab) async {
    await _database.deleteLab(lab);
  }

  Future<void> undeleteLab(String labName, int color) async {
    await _database.undeleteLab(labName, color);
  }
}
