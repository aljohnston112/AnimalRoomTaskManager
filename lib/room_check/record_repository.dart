import 'dart:collection';

import 'package:animal_room_task_manager/room_check/room_check_repository.dart';
import 'package:animal_room_task_manager/supabase_client/database.dart';
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
  final DateTime dateTime;
  final User doneBy;

  TaskRecord({
    required this.room,
    required this.task,
    required this.dateTime,
    required this.doneBy,
  });
}

class QuantitativeRecord extends TaskRecord {
  final double recordedValue;

  QuantitativeRecord({
    required super.room,
    required super.task,
    required super.dateTime,
    required super.doneBy,
    required this.recordedValue,
  });
}

/// Holds all the task records in memory
class RecordRepository extends ChangeNotifier {
  final Database _database;
  final Map<Room, Map<RoomCheckDate, Map<Task, TaskRecord>>>
  _roomToDateToTaskRecords = {};

  RecordRepository({required Database database}) : _database = database;

  void loadRecords(){
    // TODO after pushing tasks to db,
    //  make sure the database view works and parse it's output
  }

  UnmodifiableMapView<Task, TaskRecord> getRecordsForRoom(
    Room room,
    RoomCheckDate date,
    TaskFrequency frequency,
  ) {
    if (!_roomToDateToTaskRecords.containsKey(room)) {
      return UnmodifiableMapView<Task, TaskRecord>({});
    }

    var dateToTaskRecord = _roomToDateToTaskRecords[room]!;
    switch (frequency) {
      case TaskFrequency.daily:
        if (dateToTaskRecord.containsKey(date)) {
          return UnmodifiableMapView<Task, TaskRecord>(
            Map.fromEntries(
              dateToTaskRecord[date]!.entries.where((record) {
                return record.key.frequency == TaskFrequency.daily;
              }),
            ),
          );
        }
      case TaskFrequency.weekly:
        DateTime dateTime = DateTime(date.year, date.month, date.day);
        var previousSunday = dateTime.subtract(
          Duration(days: dateTime.weekday % 7),
        );
        final weekDate = previousSunday.toRoomCheckDate();
        if (dateToTaskRecord.containsKey(weekDate)) {
          return UnmodifiableMapView<Task, TaskRecord>(
            Map.fromEntries(
              dateToTaskRecord[weekDate]!.entries.where((record) {
                return record.key.frequency == TaskFrequency.weekly;
              }),
            ),
          );
        }
      case TaskFrequency.monthly:
        DateTime dateTime = DateTime(date.year, date.month, 1);
        final monthDate = dateTime.toRoomCheckDate();
        if (dateToTaskRecord.containsKey(monthDate)) {
          return UnmodifiableMapView<Task, TaskRecord>(
            Map.fromEntries(
              dateToTaskRecord[monthDate]!.entries.where((record) {
                return record.key.frequency == TaskFrequency.monthly;
              }),
            ),
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
    var records = roomRecords[roomCheckDate]!;
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
