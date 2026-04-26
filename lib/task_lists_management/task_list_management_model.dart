import 'dart:collection';

import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:flutter/foundation.dart';

class TaskListManagementModel extends ChangeNotifier {
  final TaskListRepository _taskListRepository;

  TaskListManagementModel({required TaskListRepository taskListRepository})
    : _taskListRepository = taskListRepository {
    _taskListRepository.taskLists.addListener(() {
      notifyListeners();
    });
    _taskListRepository.tasks.addListener(() {
      notifyListeners();
    });
    _taskListRepository.loadTaskLists();
    _taskListRepository.loadTasks();
    notifyListeners();
  }

  UnmodifiableMapView<TaskFrequency, Set<TaskList>> getTaskLists() {
    return _taskListRepository.taskLists.value;
  }

  UnmodifiableListView<Task> getTasks() {
    return _taskListRepository.tasks.value;
  }

  bool taskListExists(String taskListName) {
    return getTaskLists().values.any((v) {
      return v.any((v) {
        return v.name == taskListName;
      });
    });
  }

  Future<void> addTaskList(
    String taskListName,
    TaskFrequency frequency,
    Map<int, int> tidToIndex,
  ) async {
    await _taskListRepository.addTaskList(taskListName, frequency, tidToIndex);
  }

  Future<void> deleteTaskList(TaskList taskList) async {
    await _taskListRepository.deleteTaskList(taskList);
  }

  Future<void> undeleteTaskList(String taskListName) async {
    await _taskListRepository.undeleteTaskList(taskListName);
  }
}
