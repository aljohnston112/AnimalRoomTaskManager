import 'package:flutter/foundation.dart';
import 'building_repository.dart';

class BuildingManagementModel extends ChangeNotifier {
  final BuildingRepository _buildingRepository;

  BuildingManagementModel({required BuildingRepository buildingRepository})
    : _buildingRepository = buildingRepository {
    _buildingRepository.buildings.addListener(() {
      notifyListeners();
    });
    _buildingRepository.loadBuildings();
  }

  Set<Building> getBuildings() {
    return _buildingRepository.buildings.value;
  }

  bool buildingExists(String? buildingName) {
    return buildingName != null &&
        getBuildings().map((f) => f.name).contains(buildingName);
  }

  Future<void> addBuilding(String buildingName) async {
    await _buildingRepository.addBuilding(buildingName);
  }

  Future<void> deleteBuilding(Building building) async {
    await _buildingRepository.deleteFacility(building);
  }

  Future<void> undeleteBuilding(String buildingName) async {
    await _buildingRepository.undeleteBuilding(buildingName);
  }
}
