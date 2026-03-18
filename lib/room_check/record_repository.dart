import 'dart:collection';

import '../task_lists_management/task_list_repository.dart';

class TaskRecord {
  final Task task;
  final String? comment;
  final DateTime dateTime;

  TaskRecord({
    required this.task,
    required this.comment,
    required this.dateTime,
  });
}

class QuantitativeRecord extends TaskRecord {
  final double recordedValue;

  QuantitativeRecord({
    required super.task,
    required super.comment,
    required super.dateTime,
    required this.recordedValue,
  });
}

class RecordRepository {
  final Map<Task, TaskRecord> _records = {};

  UnmodifiableMapView<Task, TaskRecord> get records =>
      UnmodifiableMapView<Task, TaskRecord>(_records);

  void addRecord(TaskRecord record) {
    if (_records.containsKey(record.task)) {
      // TODO alert user someone already submitted
      // or replace based on time
    }
    _records[record.task] = record;
  }
}
