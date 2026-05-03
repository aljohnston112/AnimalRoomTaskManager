import 'package:flutter/foundation.dart';
import 'animal_repository.dart';

class AnimalManagementModel extends ChangeNotifier {
  final AnimalRepository _animalRepository;

  AnimalManagementModel({required AnimalRepository animalRepository})
    : _animalRepository = animalRepository {
    _animalRepository.animals.addListener(() {
      notifyListeners();
    });
    _animalRepository.loadAnimals();
  }

  Set<Animal> getAnimals() {
    return _animalRepository.animals.value;
  }

  bool animalExists(String? animalName) {
    return animalName != null &&
        getAnimals().map((f) => f.name).contains(animalName);
  }

  Future<void> addAnimal(String animalName) async {
    await _animalRepository.addAnimal(animalName);
  }

  Future<void> deleteAnimal(Animal animal) async {
    await _animalRepository.deleteAnimal(animal);
  }

  Future<void> undeleteAnimal(String animalName) async {
    await _animalRepository.undeleteAnimal(animalName);
  }
}
