import 'dart:collection';

import 'package:animal_room_task_manager/room_check/room_check_repository.dart';
import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:flutter/foundation.dart';
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
class RecordRepository {
  final Database _database;
  final Map<Room, Map<RoomCheckDate, Map<TaskFrequency, Map<Task, TaskRecord>>>>
  _roomToDateToFrequencyToTaskRecords = {};
  final ValueNotifier<
    Map<Room, Map<RoomCheckDate, Map<TaskFrequency, Map<Task, TaskRecord>>>>
  >
  roomToDateToFrequencyToTaskRecords = ValueNotifier({});

  RecordRepository({required Database database}) : _database = database {
    _database.subscribeToRecords((data) async {
      data = data['payload'];
      final rid = data['r_id'];
      final roomName = data['room_name'];
      final room = Room(rid: rid, name: roomName);
      DateTime date = DateTime.parse(data['date_time']);
      final taskDB = data['task_record'];
      final frequency = (taskDB['frequency'] as String).toTaskFrequency;
      date = normalizeDate(date, frequency);
      RoomCheckDate roomCheckDate = (
      year: date.year,
      month: date.month,
      day: date.day,
      );
      final tid = data['t_id'];
      final task = parseTask(taskDB, tid);
      // TODO multiple users
      var userDB = taskDB['assigned_users'][0];
      final doneBy = User(
        email: userDB['name'],
        group: UserGroup.values[userDB['ug_id']],
        uid: userDB['u_id'],
      );
      final rcid = data['rc_id'];
      double? value = data['value']?.toDouble();
      if (task is QuantitativeTask) {
        _roomToDateToFrequencyToTaskRecords[room]![roomCheckDate]![frequency]![task] =
            QuantitativeRecord(
              room: room,
              task: task,
              dateTime: date,
              doneBy: doneBy,
              rcid: rcid,
              recordedValue: value!,
            );
      } else {
        _roomToDateToFrequencyToTaskRecords[room]![roomCheckDate]![frequency]![task] =
            TaskRecord(
              room: room,
              task: task,
              dateTime: date,
              doneBy: doneBy,
              rcid: rcid,
            );
      }
      roomToDateToFrequencyToTaskRecords.value = Map.from(
        _roomToDateToFrequencyToTaskRecords,
      );
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
    roomToDateToFrequencyToTaskRecords.value = Map.from(
      _roomToDateToFrequencyToTaskRecords,
    );
  }

  void _parseTasks(PostgrestMap result) {
    final rid = result['r_id'];
    final roomName = result['room_name'];
    final room = Room(rid: rid, name: roomName);
    for (final records in result['records']) {
      DateTime date = DateTime.parse(records['date_time']);
      for (final record in records['records']) {
          final trid = record['tr_id'];
          final rcid = record['rc_id'];
          final taskDB = record['task'];
          final tid = record['t_id'];
          double? value = record['recorded_value']?.toDouble();
          final frequency = (taskDB['frequency'] as String).toTaskFrequency;
          date = normalizeDate(date, frequency);
          RoomCheckDate roomCheckDate = (
            year: date.year,
            month: date.month,
            day: date.day,
          );

          // TODO multiple users
          var userDB = taskDB['assigned_users'][0];
          final doneBy = User(
            email: userDB['name'],
            group: UserGroup.values[userDB['ug_id']],
            uid: userDB['u_id'],
          );

          final task = parseTask(taskDB, tid);
          if (!_roomToDateToFrequencyToTaskRecords.containsKey(room)) {
            _roomToDateToFrequencyToTaskRecords[room] = {};
          }
          if (!_roomToDateToFrequencyToTaskRecords[room]!.containsKey(
            roomCheckDate,
          )) {
            _roomToDateToFrequencyToTaskRecords[room]![roomCheckDate] = {};
          }
          if (!_roomToDateToFrequencyToTaskRecords[room]![roomCheckDate]!
              .containsKey(frequency)) {
            _roomToDateToFrequencyToTaskRecords[room]![roomCheckDate]![frequency] =
                {};
          }
          if (task is QuantitativeTask) {
            _roomToDateToFrequencyToTaskRecords[room]![roomCheckDate]![frequency]![task] =
                QuantitativeRecord(
                  room: room,
                  task: task,
                  dateTime: date,
                  doneBy: doneBy,
                  rcid: rcid,
                  recordedValue: value!,
                );
          } else {
            _roomToDateToFrequencyToTaskRecords[room]![roomCheckDate]![frequency]![task] =
                TaskRecord(
                  room: room,
                  task: task,
                  dateTime: date,
                  doneBy: doneBy,
                  rcid: rcid,
                );
        }
      }
    }
  }

  UnmodifiableMapView<Task, TaskRecord> getRecordsForRoom(
    Room room,
    RoomCheckDate date,
    TaskFrequency frequency,
  ) {
    if (!_roomToDateToFrequencyToTaskRecords.containsKey(room)) {
      return UnmodifiableMapView<Task, TaskRecord>({});
    }

    date = normalizeRoomCheckDate(date, frequency);
    var dateToTaskRecord = _roomToDateToFrequencyToTaskRecords[room]!;
    if (dateToTaskRecord.containsKey(date) &&
        dateToTaskRecord[date]!.containsKey(frequency)) {
      return UnmodifiableMapView<Task, TaskRecord>(
        Map.fromEntries(dateToTaskRecord[date]![frequency]!.entries),
      );
    }

    return UnmodifiableMapView<Task, TaskRecord>({});
  }

  Future<bool> addRecord(TaskRecord record, TaskFrequency frequency) async {
    var date = normalizeDate(record.dateTime, frequency).toRoomCheckDate();
    if (_roomToDateToFrequencyToTaskRecords[record
            .room]?[date]?[frequency]?[record.task] ==
        null) {
      return await _database.insertRecord(record);
    }
    return true;
  }
}
