import 'package:animal_room_task_manager/room_check/record_repository.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:flutter/cupertino.dart';

class TaskEntry {
  final Task task;
  final TaskRecord? record;

  TaskEntry({required this.task, this.record});

  bool get isCompleted => record != null;
}

class RoomCheckModel extends ChangeNotifier {
  final TaskList taskList;
  final RecordRepository _recordRepository;

  final Map<Task, TextEditingController> _commentControllers = {};
  final Map<Task, TextEditingController> _valueControllers = {};
  final Set<Task> _tasksWithComments = {};
  final Set<Task> _completedTasks = {};

  RoomCheckModel({
    required this.taskList,
    required RecordRepository recordRepository,
  }) : _recordRepository = recordRepository {
    {
      for (var task in taskList.tasks) {
        _commentControllers[task] = TextEditingController();
        _valueControllers[task] = TextEditingController();
      }
    }
  }

  List<TaskEntry> get getTaskRecord => taskList.tasks
      .map(
        (task) =>
            TaskEntry(task: task, record: _recordRepository.records[task]),
      )
      .toList();

  TextEditingController getCommentController(Task task) =>
      _commentControllers[task]!;

  TextEditingController getValueController(Task task) =>
      _valueControllers[task]!;

  bool hasComment(Task task) => _tasksWithComments.contains(task);

  bool isTaskCompleted(Task task) => _completedTasks.contains(task);

  void toggleTask(Task task, bool? checked) {
    if (checked == true) {
      _completedTasks.add(task);
    } else {
      _completedTasks.remove(task);
    }
    notifyListeners();
  }

  void addCommentField(Task task) {
    _tasksWithComments.add(task);
    notifyListeners();
  }

  @override
  void dispose() {
    for (var c in _commentControllers.values) {
      c.dispose();
    }
    for (var c in _valueControllers.values) {
      c.dispose();
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
            task: task,
            comment: comment,
            dateTime: DateTime.now(),
            recordedValue: double.parse(valueText!),
          ),
        );
      } else if (_completedTasks.contains(task)) {
        _recordRepository.addRecord(
          TaskRecord(task: task, comment: comment, dateTime: DateTime.now()),
        );
      }
    }
    notifyListeners();
  }
}
