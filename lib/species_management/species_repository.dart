import 'package:flutter/material.dart';
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
  final ValueNotifier<Set<Species>> allSpecies = ValueNotifier({});

  SpeciesRepository({required Database database}) : _database = database {
    _database.subscribeToAnimals((PostgresChangePayload p) {
      var newRecord = p.newRecord;
      if (newRecord.isNotEmpty) {
        var species = _parseSpecies(newRecord);
        _species.remove(species);
        if (!newRecord['deleted']) {
          _species.add(species);
        }
        allSpecies.value = Set.from(_species);
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
        allSpecies.value.add(species);
      }
    }
    allSpecies.value = Set.from(_species);
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
