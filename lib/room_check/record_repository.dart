import 'dart:collection';

import '../task_lists_management/task_list_repository.dart';

/// The record of a task.
/// Two records with the same task
/// cannot share the same room and date as one another.
class TaskRecord {
  final String roomName;
  final Task task;
  final String? comment;
  final DateTime dateTime;

  TaskRecord({
    required this.roomName,
    required this.task,
    required this.comment,
    required this.dateTime,
  });
}

class QuantitativeRecord extends TaskRecord {
  final double recordedValue;

  QuantitativeRecord({
    required super.roomName,
    required super.task,
    required super.comment,
    required super.dateTime,
    required this.recordedValue,
  });
}

/// Holds all the task records in memory
class RecordRepository {
  final Map<String, Map<Task, TaskRecord>> _records = {};

  RecordRepository();
  
  UnmodifiableMapView<Task, TaskRecord> getRecordsForRoom(String roomName) =>
      UnmodifiableMapView<Task, TaskRecord>(
        Map.fromEntries(
          _records[roomName] != null ? _records[roomName]!.entries : {},
        ),
      );

  void addRecord(TaskRecord record) {
    if(!_records.containsKey(record.roomName)){
      _records[record.roomName] = {};
    }
    var records = _records[record.roomName]!;
    if (records.containsKey(record.task)) {
      // TODO this should never happen
    }
    records[record.task] = record;
  }

  /// TODO for local user testing only
  /// delete this once data needs to be persisted
  void clear() {
    _records.clear();
  }
}
