import 'package:flutter/foundation.dart';
import 'building_repository.dart';

class BuildingManagementModel extends ChangeNotifier {
  final BuildingRepository _buildingRepository;

  BuildingManagementModel({required BuildingRepository buildingRepository})
    : _buildingRepository = buildingRepository {
    _buildingRepository.buildingsListenable.addListener(() {
      notifyListeners();
    });
    _buildingRepository.loadBuildings();
  }

  Set<Building> get buildings => _buildingRepository.buildingsListenable.value;


  bool buildingExists(String? buildingName) {
    return buildingName != null &&
        buildings.map((f) => f.name).contains(buildingName);
  }

  Future<void> addBuilding(String buildingName) async {
    await _buildingRepository.addBuilding(buildingName);
  }

  Future<void> deleteBuilding(Building building) async {
    await _buildingRepository.deleteBuilding(building);
  }

  Future<void> undeleteBuilding(String buildingName) async {
    await _buildingRepository.undeleteBuilding(buildingName);
  }
}
