import 'dart:collection';

import 'package:animal_room_task_manager/query/query_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_client/database.dart';

class Species {
  final int aid;
  final String name;

  Species({required this.aid, required this.name});

  @override
  bool operator ==(Object other) => other is Species && other.aid == aid;

  @override
  int get hashCode => aid.hashCode;
}

class SpeciesRepository {
  final Database _database;

  final Set<Species> _species = {};
  late final _speciesNotifier = RefreshableNotifier(
    UnmodifiableSetView(_species),
  );
  late final ValueListenable<UnmodifiableSetView<Species>> speciesListenable =
      _speciesNotifier;

  Set<Species> get species => _species;

  SpeciesRepository({required Database database}) : _database = database {
    _database.subscribeToAnimals((PostgresChangePayload p) {
      var newRecord = p.newRecord;
      if (newRecord.isNotEmpty) {
        var species = _parseSpecies(newRecord);
        _species.remove(species);
        if (!newRecord['deleted']) {
          _species.add(species);
        }
        _speciesNotifier.refresh();
      }
    });
  }

  Species _parseSpecies(PostgrestMap species) {
    return Species(aid: species['a_id'], name: species['name']);
  }

  Future<void> loadSpecies() async {
    final result = await _database.getAnimals();
    for (final speciesDB in result) {
      Species species = _parseSpecies(speciesDB);
      if (!speciesDB['deleted']) {
        _species.add(species);
      }
    }
    _speciesNotifier.refresh();
  }

  Future<void> addSpecies(String speciesName) {
    return _database.insertAnimal(speciesName);
  }

  Future<void> deleteSpecies(Species species) async {
    await _database.deleteAnimal(species);
  }

  Future<void> undeleteSpecies(String speciesName) async {
    await _database.undeleteAnimal(speciesName);
  }
}
