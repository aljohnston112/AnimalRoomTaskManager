import 'package:flutter/cupertino.dart';
import 'lab_repository.dart';

class LabManagementModel extends ChangeNotifier {
  final LabRepository _labRepository;

  LabManagementModel({required LabRepository labRepository})
    : _labRepository = labRepository {
    _labRepository.labs.addListener(() {
      notifyListeners();
    });
    _labRepository.loadLabs();
  }

  Set<Lab> getLabs() {
    return _labRepository.labs.value;
  }

  bool labExists(String? labName) {
    return labName != null && getLabs().map((l) => l.name).contains(labName);
  }

  bool existingLabHasColor(Color? currentColor) {
    return currentColor != null &&
        getLabs().map((l) => l.color).contains(currentColor);
  }

  Future<void> addLab(String labName, Color color) async {
    await _labRepository.addLab(labName, color.toARGB32());
  }

  Future<void> deleteLab(Lab lab) async {
    await _labRepository.deleteLab(lab);
  }

  Future<void> undeleteLab(String labName) async {
    await _labRepository.undeleteLab(labName);
  }
}
