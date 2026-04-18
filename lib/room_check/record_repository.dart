import 'dart:collection';

import 'package:animal_room_task_manager/room_check/room_check_repository.dart';
import 'package:flutter/cupertino.dart';

import '../scheduler/scheduling_model.dart';
import '../task_lists_management/task_list_repository.dart';
import '../user_management/user_repository.dart';

extension ToRoomCheckDate on DateTime {
  RoomCheckDate toRoomCheckDate() {
    return (year: year, month: month, day: day);
  }
}

/// The record of a task.
/// Two records with the same task
/// cannot share the same room and date as one another.
class TaskRecord {
  final Room room;
  final Task task;
  final String? comment;
  final DateTime dateTime;
  final User doneBy;

  TaskRecord({
    required this.room,
    required this.task,
    required this.comment,
    required this.dateTime,
    required this.doneBy,
  });
}

class QuantitativeRecord extends TaskRecord {
  final double recordedValue;

  QuantitativeRecord({
    required super.room,
    required super.task,
    required super.comment,
    required super.dateTime,
    required super.doneBy,
    required this.recordedValue,
  });
}

/// Holds all the task records in memory
class RecordRepository extends ChangeNotifier {
  final Map<Room, Map<RoomCheckDate, Map<Task, TaskRecord>>>
  _roomToDateToTaskRecords = {};

  RecordRepository();

  UnmodifiableMapView<Task, TaskRecord> getRecordsForRoom(
    Room room,
    RoomCheckDate date,
  ) {
    if (_roomToDateToTaskRecords[room] != null) {
      if (_roomToDateToTaskRecords[room]![date] != null) {
        return UnmodifiableMapView<Task, TaskRecord>(
          Map.fromEntries(_roomToDateToTaskRecords[room]![date]!.entries),
        );
      }
    }
    return UnmodifiableMapView<Task, TaskRecord>({});
  }

  bool addRecord(TaskRecord record) {
    if (!_roomToDateToTaskRecords.containsKey(record.room)) {
      _roomToDateToTaskRecords[record.room] = {};
    }
    var roomRecords = _roomToDateToTaskRecords[record.room]!;
    var recordDate = record.dateTime;
    final roomCheckDate = recordDate.toRoomCheckDate();
    if (!roomRecords.containsKey(roomCheckDate)) {
      roomRecords[roomCheckDate] = {};
    }
    var records = _roomToDateToTaskRecords[record.room]![roomCheckDate]!;
    if (records.containsKey(record.task)) {
      return false;
    }
    records[record.task] = record;
    notifyListeners();
    return true;
  }

  /// TODO for local user testing only
  /// delete this once data needs to be persisted
  void clear() {
    _roomToDateToTaskRecords.clear();
    notifyListeners();
  }
}
