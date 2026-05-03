import 'package:animal_room_task_manager/animal_management/animal_repository.dart';
import 'package:flutter/foundation.dart';

class Census {
  final Animal animal;
  final int quantity;

  Census({required this.animal, required this.quantity});
}

class CensusScreenModel {
  List<Census> _censusEntries = [];

  ValueNotifier<List<Census>> censusEntries = ValueNotifier([]);

  CensusScreenModel({required Census? census}) {
    census != null ? _censusEntries.add(census) : null;
    censusEntries.value = _censusEntries;
  }

  void addCensusEntry(Census census) {
    _censusEntries.add(census);
    censusEntries.value = List.from(_censusEntries);
  }

  void submitCensus() {
    // TODO
  }
}

class CensusEntryModel extends ChangeNotifier {
  ValueNotifier<Set<Animal>> animals = ValueNotifier({});

  CensusEntryModel({required AnimalRepository animalRepository}) {
    animals = animalRepository.animals;
    animalRepository.loadAnimals();
  }

  Animal getAnimal(int aid) {
    return animals.value.firstWhere((a) => a.aid == aid);
  }
}
