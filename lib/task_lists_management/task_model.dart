import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:flutter/foundation.dart';

class TaskModel extends ChangeNotifier {
  final TaskListRepository _taskListRepository;

  bool _isQuantitative = false;
  bool _isManagerOnly = false;
  bool _needsWarningRange = false;
  bool _needsRequiredRange = false;

  TaskModel({required TaskListRepository taskListRepository})
    : _taskListRepository = taskListRepository {
    _taskListRepository.loadTasks();
  }

  bool get isQuantitative => _isQuantitative;

  void toggleQuantitative(bool value) {
    _isQuantitative = !_isQuantitative;
    notifyListeners();
  }

  bool get isManagerOnly => _isManagerOnly;

  void toggleManagerOnly(bool value) {
    _isManagerOnly = !_isManagerOnly;
    notifyListeners();
  }

  bool taskDescriptionExists(String value) {
    return _taskListRepository.taskDescriptionExists(value);
  }

  bool get needsWarningRange => _needsWarningRange;

  void toggleNeedsWarningRange(bool value) {
    _needsWarningRange = !_needsWarningRange;
    notifyListeners();
  }

  bool get needsRequiredRange => _needsRequiredRange;

  void toggleNeedsRequiredRange(bool value) {
    _needsRequiredRange = !_needsRequiredRange;
    notifyListeners();
  }

  Future<void> addQuantitativeTask(
    String description,
    QuantitativeRange<double>? warningRange,
    QuantitativeRange<double>? requiredRange,
  ) async {
    _taskListRepository.addQuantitativeTask(
      description,
      _isManagerOnly,
      warningRange,
      requiredRange,
    );
  }

  Future<void> addTask(String description, bool isManagerOnly) async {
    _taskListRepository.addTask(description, isManagerOnly);
  }

  void refreshTasks() {
    _taskListRepository.loadTasks();
  }
}
