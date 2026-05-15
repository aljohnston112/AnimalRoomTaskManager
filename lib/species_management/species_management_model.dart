import 'package:flutter/foundation.dart';
import 'species_repository.dart';

class SpeciesManagementModel extends ChangeNotifier {
  final SpeciesRepository _speciesRepository;

  SpeciesManagementModel({required SpeciesRepository speciesRepository})
    : _speciesRepository = speciesRepository {
    _speciesRepository.allSpecies.addListener(() {
      notifyListeners();
    });
    _speciesRepository.loadSpecies();
  }

  Set<Species> getSpecies() {
    return _speciesRepository.allSpecies.value;
  }

  bool speciesExists(String? speciesName) {
    return speciesName != null &&
        getSpecies().map((f) => f.name).contains(speciesName);
  }

  Future<void> addSpecies(String speciesName) async {
    await _speciesRepository.addSpecies(speciesName);
  }

  Future<void> deleteSpecies(Species species) async {
    await _speciesRepository.deleteSpecies(species);
  }

  Future<void> undeleteSpecies(String speciesName) async {
    await _speciesRepository.undeleteSpecies(speciesName);
  }
}
