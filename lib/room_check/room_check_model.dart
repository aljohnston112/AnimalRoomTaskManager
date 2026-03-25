import 'package:animal_room_task_manager/room_check/record_repository.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:flutter/cupertino.dart';

class TaskEntry {
  final Task task;
  final TaskRecord? record;

  TaskEntry({required this.task, required this.record});

  bool get isCompleted => record != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskEntry && task == other.task && record == other.record;

  @override
  int get hashCode => task.hashCode ^ record.hashCode;
}

class RoomCheckModel extends ChangeNotifier {
  final String roomName;
  final TaskList taskList;
  final RecordRepository _recordRepository;

  final Map<Task, TextEditingController> _commentControllers = {};
  final Map<Task, TextEditingController> _valueControllers = {};
  final Set<Task> _tasksWithACommentField = {};
  final Set<Task> _completedTasks = {};

  RoomCheckModel({
    required this.roomName,
    required this.taskList,
    required RecordRepository recordRepository,
  }) : _recordRepository = recordRepository {
    {
      for (var task in taskList.tasks) {
        _commentControllers[task] = TextEditingController();
        if(task is QuantitativeTask) {
          _valueControllers[task] = TextEditingController();
        }
      }
      recordRepository.getRecordsForRoom(roomName).forEach((task, record) {
          _tasksWithACommentField.add(task);
          if (record.comment != null) {
            _commentControllers[task]?.text = record.comment!;
          }
          if (record is QuantitativeRecord) {
            _valueControllers[task]?.text = record.recordedValue.toString();
          }
          _completedTasks.add(task);
      });
    }
  }

  List<TaskEntry> get taskEntries => taskList.tasks
      .map(
        (task) => TaskEntry(
          task: task,
          record: _recordRepository.getRecordsForRoom(roomName)[task],
        ),
      )
      .toList();

  TextEditingController getCommentController(Task task) =>
      _commentControllers[task]!;

  TextEditingController getValueController(Task task) =>
      _valueControllers[task]!;

  bool doesTaskHaveComment(Task task) => _tasksWithACommentField.contains(task);

  bool isTaskCompleted(Task task) => _completedTasks.contains(task);

  void toggleTaskCompletion(Task task, bool? completed) {
    if (completed == true) {
      _completedTasks.add(task);
    } else {
      _completedTasks.remove(task);
    }
    notifyListeners();
  }

  void onAddCommentClicked(Task task) {
    _tasksWithACommentField.add(task);
    notifyListeners();
  }

  @override
  void dispose() {
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    for (var controller in _valueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void submit() {
    for (var task in taskList.tasks) {
      String? comment = _commentControllers[task]?.text;
      String? valueText = _valueControllers[task]?.text;
      if (valueText?.isNotEmpty == true) {
        _recordRepository.addRecord(
          QuantitativeRecord(
            roomName: roomName,
            task: task,
            comment: comment,
            dateTime: DateTime.now(),
            recordedValue: double.parse(valueText!),
          ),
        );
      } else if (_completedTasks.contains(task)) {
        _recordRepository.addRecord(
          TaskRecord(
            roomName: roomName,
            task: task,
            comment: comment,
            dateTime: DateTime.now(),
          ),
        );
      }
    }
    notifyListeners();
  }

  bool hasUnsavedComments() {
    for(var task in _tasksWithACommentField) {
      if (!_recordRepository.getRecordsForRoom(roomName).containsKey(task)) {
        return true;
      }
    }
    return false;
  }

  bool isTaskRecorded(Task task) {
    return _recordRepository.getRecordsForRoom(roomName).containsKey(task);
  }

}
