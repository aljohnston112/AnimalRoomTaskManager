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
  late final RoomCheckSlot _roomCheckSlot;
  final Room room;
  final TaskList taskList;
  final RecordRepository _recordRepository;
  final RoomCheckRepository _roomCheckRepository;
  final LoginUseCase loginUseCase;
  final RoomCheckDate date;

  final TextEditingController _commentController;
  final Map<Task, TextEditingController> _quantitativeValueControllers = {};

  final Set<Task> _completedTasks = {};
  bool _shouldHaveADisplayedCommentField;

  RoomCheckModel({
    required this.room,
    required this.taskList,
    required RecordRepository recordRepository,
    required RoomCheckRepository roomCheckRepository,
    required this.loginUseCase,
    required this.date,
    required RoomCheckSlot? roomCheckSlot,
  }) : _recordRepository = recordRepository,
       _roomCheckRepository = roomCheckRepository,
       _commentController = TextEditingController(),
       _shouldHaveADisplayedCommentField = roomCheckSlot?.comment != null {
    // TODO rcid is missing when the record is in the database
    if (roomCheckSlot != null) {
      _roomCheckSlot = roomCheckSlot;
    } else {
      _roomCheckSlot = RoomCheckSlot(
        rcid: null,
        date: date,
        rid: room.rid,
        roomName: room.name,
        frequency: taskList.frequency,
        comment: null,
        uid: loginUseCase.loggedInUser?.uid,
        assigned: loginUseCase.loggedInUser?.email,
        state: RoomCheckState.started,
      );
      roomCheckRepository.updateRoomCheck(_roomCheckSlot);
    }

    // Initialize input controllers
    for (var task in taskList.tasks) {
      if (task is QuantitativeTask) {
        _quantitativeValueControllers[task] = TextEditingController();
      }
    }

    if (roomCheckSlot?.comment case String comment) {
      _commentController.text = comment;
    }

    // Add recorded tasks
    recordRepository.getRecordsForRoom(room, date, taskList.frequency).forEach((
      task,
      record,
    ) {
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
    var records = _recordRepository.getRecordsForRoom(
      room,
      date,
      taskList.frequency,
    );
    return taskList.tasks
        .map(
          (task) =>
              TaskEntryModel(task: task, record: records[task], date: date),
        )
        .toList();
  }

  TextEditingController getCommentController() {
    return _commentController;
  }

  TextEditingController getQuantitativeValueController(Task task) =>
      _quantitativeValueControllers[task]!;

  bool shouldCommentBeDisplayed() => _shouldHaveADisplayedCommentField;

  bool isTaskCompleted(Task task) => _completedTasks.contains(task);

  /// This toggles the completion status before submission.
  void toggleTaskCompletion(Task task, bool? completed) {
    var records = _recordRepository.getRecordsForRoom(
      room,
      date,
      taskList.frequency,
    );
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

  void onAddCommentClicked() {
    _shouldHaveADisplayedCommentField = true;
    _commentController.text = "";
    notifyListeners();
  }

  bool isTaskRecorded(Task task) {
    return _recordRepository
        .getRecordsForRoom(room, date, taskList.frequency)
        .containsKey(task);
  }

  bool submit() {
    bool allRecordsAdded = true;
    String? comment = _commentController.text;
    if (comment != _roomCheckSlot.comment) {
      _roomCheckRepository.saveComment(_roomCheckSlot, comment);
    }
    for (var task in taskList.tasks) {
      String? valueText = _quantitativeValueControllers[task]?.text;
      User? loggedInUser = loginUseCase.loggedInUser;
      if (loggedInUser != null) {
        bool wasRecordAdded = true;
        if (valueText?.isNotEmpty == true) {
          wasRecordAdded = _recordRepository.addRecord(
            QuantitativeRecord(
              room: room,
              task: task,
              dateTime: DateTime.now(),
              recordedValue: double.parse(valueText!),
              doneBy: loggedInUser,
            ),
          );
        } else if (_completedTasks.contains(task)) {
          wasRecordAdded = _recordRepository.addRecord(
            TaskRecord(
              room: room,
              task: task,
              dateTime: DateTime.now(),
              doneBy: loggedInUser,
            ),
          );
        }
        if (!wasRecordAdded) {
          allRecordsAdded = false;
        }
      }
    }
    notifyListeners();
    return allRecordsAdded;
  }

  bool hasUnsavedTasks() {
    bool unsaved = false;
    var records = _recordRepository.getRecordsForRoom(
      room,
      date,
      taskList.frequency,
    );
    for (var task in _completedTasks) {
      if (!records.containsKey(task)) {
        unsaved = true;
        break;
      }
    }
    return unsaved;
  }

  bool hasUnsavedComment() {
    return _shouldHaveADisplayedCommentField &&
        _commentController.text.isNotEmpty &&
        _commentController.text != _roomCheckSlot.comment;
  }

  @override
  void dispose() {
    _commentController.dispose();
    for (var controller in _quantitativeValueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? getSavedComment() {
    return _roomCheckSlot.comment;
  }
}
