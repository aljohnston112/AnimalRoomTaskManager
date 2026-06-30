import 'package:flutter/cupertino.dart';
import 'facility_repository.dart';

class FacilityManagementModel extends ChangeNotifier {
  final FacilityRepository _facilityRepository;

  FacilityManagementModel({required FacilityRepository facilityRepository})
    : _facilityRepository = facilityRepository {
    _facilityRepository.facilitiesListenable.addListener(() {
      notifyListeners();
    });
    _facilityRepository.loadFacilities();
  }

  Set<Facility> get facilities => _facilityRepository.facilitiesListenable.value;

  bool facilityExists(String? facilityName) {
    return facilityName != null &&
        facilities.map((f) => f.name).contains(facilityName);
  }

  Future<void> addFacility(String facilityName) async {
    await _facilityRepository.addFacility(facilityName);
  }

  Future<void> deleteFacility(Facility facility) async {
    await _facilityRepository.deleteFacility(facility);
  }

  Future<void> undeleteFacility(String facilityName) async {
    await _facilityRepository.undeleteFacility(facilityName);
  }
}
