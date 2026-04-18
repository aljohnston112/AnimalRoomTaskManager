import 'package:animal_room_task_manager/login_screen/login_use_case.dart';
import 'package:animal_room_task_manager/room_check/record_repository.dart';
import 'package:animal_room_task_manager/room_check/room_check_repository.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:flutter/cupertino.dart';

import '../scheduler/scheduling_model.dart';
import '../user_management/user_repository.dart';

/// User task entry model
/// The task record is final and complete when the record is not null
class TaskEntryModel {
  final Task task;
  final TaskRecord? record;
  final RoomCheckDate date;

  TaskEntryModel({
    required this.task,
    required this.record,
    required this.date,
  });

  bool get isCompleted => record != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskEntryModel && task == other.task && record == other.record;

  @override
  int get hashCode => task.hashCode ^ record.hashCode;
}

enum RoomCheckStatus { notStarted, started, done }

class RoomCheckModel extends ChangeNotifier {
  final Room room;
  final TaskList taskList;
  final RecordRepository _recordRepository;
  final LoginUseCase loginUseCase;
  final RoomCheckDate date;

  final Map<Task, TextEditingController> _commentControllers = {};
  final Map<Task, TextEditingController> _quantitativeValueControllers = {};

  final Set<Task> _tasksThatShouldHaveADisplayedCommentField = {};
  final Set<Task> _completedTasks = {};

  RoomCheckModel({
    required this.room,
    required this.taskList,
    required RecordRepository recordRepository,
    required this.loginUseCase,
    required this.date,
  }) : _recordRepository = recordRepository {
    // Initialize input controllers
    for (var task in taskList.tasks) {
      _commentControllers[task] = TextEditingController();
      if (task is QuantitativeTask) {
        _quantitativeValueControllers[task] = TextEditingController();
      }
    }

    // Add recorded tasks
    recordRepository.getRecordsForRoom(room, date).forEach((task, record) {
      _tasksThatShouldHaveADisplayedCommentField.add(task);
      if (record.comment case String comment) {
        _commentControllers[task]?.text = comment;
      }
      if (record is QuantitativeRecord) {
        _quantitativeValueControllers[task]?.text = record.recordedValue
            .toString();
      }
      _completedTasks.add(task);
    });
  }

  /// Gets the tasks for the room check this model represents including
  /// any that have already been completed
  List<TaskEntryModel> getTaskEntries() {
    var records = _recordRepository.getRecordsForRoom(room, date);
    return taskList.tasks
        .map(
          (task) =>
              TaskEntryModel(task: task, record: records[task], date: date),
        )
        .toList();
  }

  TextEditingController getCommentController(Task task) =>
      _commentControllers[task]!;

  TextEditingController getQuantitativeValueController(Task task) =>
      _quantitativeValueControllers[task]!;

  bool shouldCommentBeDisplayedForTask(Task task) =>
      _tasksThatShouldHaveADisplayedCommentField.contains(task);

  bool isTaskCompleted(Task task) => _completedTasks.contains(task);

  /// This toggles the completion status before submission.
  void toggleTaskCompletion(Task task, bool? completed) {
    var records = _recordRepository.getRecordsForRoom(room, date);
    if (records[task] != null) {
      throw Exception("Submitted tasks can not have their completion toggled");
    }
    if (completed == true) {
      _completedTasks.add(task);
    } else {
      _completedTasks.remove(task);
    }
    notifyListeners();
  }

  void onAddCommentClicked(Task task) {
    _tasksThatShouldHaveADisplayedCommentField.add(task);
    notifyListeners();
  }

  bool hasUnsavedComments() {
    var records = _recordRepository.getRecordsForRoom(room, date);
    for (var task in _tasksThatShouldHaveADisplayedCommentField) {
      if (!records.containsKey(task)) {
        return true;
      }
    }
    return false;
  }

  bool isTaskRecorded(Task task) {
    return _recordRepository.getRecordsForRoom(room, date).containsKey(task);
  }

  void submit() {
    for (var task in taskList.tasks) {
      String? comment = _commentControllers[task]?.text;
      String? valueText = _quantitativeValueControllers[task]?.text;
      User? loggedInUser = loginUseCase.loggedInUser;
      if (loggedInUser != null) {
        if (valueText?.isNotEmpty == true) {
          _recordRepository.addRecord(
            QuantitativeRecord(
              room: room,
              task: task,
              comment: comment,
              dateTime: DateTime.now(),
              recordedValue: double.parse(valueText!),
              doneBy: loggedInUser,
            ),
          );
        } else if (_completedTasks.contains(task)) {
          _recordRepository.addRecord(
            TaskRecord(
              room: room,
              task: task,
              comment: comment,
              dateTime: DateTime.now(),
              doneBy: loggedInUser,
            ),
          );
        }
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    for (var controller in _quantitativeValueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
