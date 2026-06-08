import 'package:flutter/foundation.dart';

import 'species_repository.dart';

class SpeciesManagementModel extends ChangeNotifier {
  final SpeciesRepository _speciesRepository;

  SpeciesManagementModel({required SpeciesRepository speciesRepository})
    : _speciesRepository = speciesRepository {
    _speciesRepository.speciesListenable.addListener(() {
      notifyListeners();
    });
    _speciesRepository.loadSpecies();
  }

  Set<Species> get species => _speciesRepository.species;

  bool speciesExists(String? speciesName) {
    return speciesName != null &&
        species.map((f) => f.name).contains(speciesName);
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
