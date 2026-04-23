import 'dart:collection';

import 'package:animal_room_task_manager/room_check/room_check_repository.dart';
import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

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
  final int rcid;

  TaskRecord({
    required this.room,
    required this.task,
    required this.dateTime,
    required this.doneBy,
    required this.rcid,
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
    required super.rcid,
  });
}

/// Holds all the task records in memory
class RecordRepository extends ChangeNotifier {
  final Database _database;
  final Map<Room, Map<RoomCheckDate, Map<Task, TaskRecord>>>
  _roomToDateToTaskRecords = {};

  RecordRepository({required Database database}) : _database = database {
    _database.subscribeToRecords((data) {
      final payload = data['payload'];
      _parseTasks(payload);
      notifyListeners();
    });
  }

  Future<void> loadRecords() async {
    final data = await _database.getRecords();
    for (final d in data) {
      final results = d['result'];
      if (results != null) {
        for (final result in results) {
          _parseTasks(result);
        }
      }
    }
  }

  void _parseTasks(PostgrestMap result) {
    final rid = result['r_id'];
    final roomName = result['room_name'];
    final room = Room(rid: rid, name: roomName);
    for (final records in result['records']) {
      final recordsForDates = records['dates'];
      for (final recordsForDate in recordsForDates) {
        DateTime parsedDate = DateTime.parse(recordsForDate['date_time']);
        RoomCheckDate roomCheckDate = (
          year: parsedDate.year,
          month: parsedDate.month,
          day: parsedDate.day,
        );
        final records = recordsForDate['records'];
        for (final record in records) {
          final trid = record['tr_id'];
          final rcid = record['rc_id'];
          final taskDB = record['task'];
          final tid = record['t_id'];
          double? value = record['recorded_value'];
          final frequency = (taskDB['frequency'] as String).toTaskFrequency;
          // TODO multiple users
          var userDB = taskDB['assigned_users'][0];
          final doneBy = User(
            email: userDB['name'],
            group: UserGroup.values[userDB['ug_id']],
            uid: userDB['u_id'],
          );

          final task = parseTask(taskDB, frequency, tid);
          if (!_roomToDateToTaskRecords.containsKey(room)) {
            _roomToDateToTaskRecords[room] = {};
          }
          if (!_roomToDateToTaskRecords[room]!.containsKey(roomCheckDate)) {
            _roomToDateToTaskRecords[room]![roomCheckDate] = {};
          }
          if (task is QuantitativeTask) {
            _roomToDateToTaskRecords[room]![roomCheckDate]![task] =
                QuantitativeRecord(
                  room: room,
                  task: task,
                  dateTime: parsedDate,
                  doneBy: doneBy,
                  rcid: rcid,
                  recordedValue: value!,
                );
          } else {
            _roomToDateToTaskRecords[room]![roomCheckDate]![task] = TaskRecord(
              room: room,
              task: task,
              dateTime: parsedDate,
              doneBy: doneBy,
              rcid: rcid,
            );
          }
        }
      }
    }
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

  Future<bool> addRecord(TaskRecord record) async {
    if (_roomToDateToTaskRecords[record.room]?[record.dateTime
            .toRoomCheckDate()]?[record.task] ==
        null) {
      return await _database.insertRecord(record);
    }
    return true;
  }

  /// TODO for local user testing only
  /// delete this once data needs to be persisted
  void clear() {
    _roomToDateToTaskRecords.clear();
    notifyListeners();
  }
}
