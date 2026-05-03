import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Animal {
  final int aid;
  final String name;

  Animal({required this.aid, required this.name});

  @override
  bool operator ==(Object other) => other is Animal && other.aid == aid;

  @override
  int get hashCode => aid.hashCode;
}

class AnimalRepository {
  final Database _database;
  final Set<Animal> _animals = {};
  final ValueNotifier<Set<Animal>> animals = ValueNotifier({});

  AnimalRepository({required Database database}) : _database = database {
    _database.subscribeToAnimals((PostgresChangePayload p) {
      var newRecord = p.newRecord;
      if (newRecord.isNotEmpty) {
        var animal = _parseAnimal(newRecord);
        _animals.remove(animal);
        if (!newRecord['deleted']) {
          _animals.add(animal);
        }
        animals.value = Set.from(_animals);
      }
    });
  }

  Animal _parseAnimal(PostgrestMap animal) {
    return Animal(aid: animal['a_id'], name: animal['name']);
  }

  Future<void> loadAnimals() async {
    final result = await _database.getAnimals();
    for (final animalDB in result) {
      Animal animal = _parseAnimal(animalDB);
      if (!animalDB['deleted']) {
        _animals.add(animal);
      }
    }
    animals.value = Set.from(_animals);
  }

  Future<void> addAnimal(String animalName) {
    return _database.insertAnimal(animalName);
  }

  Future<void> deleteAnimal(Animal animal) async {
    await _database.deleteAnimal(animal);
  }

  Future<void> undeleteAnimal(String animalName) async {
    await _database.undeleteAnimal(animalName);
  }
}
