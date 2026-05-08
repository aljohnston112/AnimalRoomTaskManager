import 'dart:math';

import 'package:animal_room_task_manager/query/query_model.dart';
import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:flutter/foundation.dart';

final Set<String> _dateStringPool = {};
final Set<String> _roomStringPool = {};
final Set<String> _userStringPool = {};
final Set<String> _taskStringPool = {};
final Set<String> _valueStringPool = {};

enum RowType { date, room, user, task, value }

final Map<RowType, Set<String>> _rowTypeToStringPool = {
  RowType.date: _dateStringPool,
  RowType.room: _roomStringPool,
  RowType.user: _userStringPool,
  RowType.task: _taskStringPool,
  RowType.value: _valueStringPool,
};

class QueryRepository {
  final Database _database;

  final RefreshableNotifier<List<QueryData>> recordsNotifier =
      RefreshableNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(true);

  final ValueNotifier<String> _longestDate = ValueNotifier<String>("");
  late ValueListenable<String> longestDate = _longestDate;

  final ValueNotifier<String> _longestRoom = ValueNotifier<String>("");
  late ValueListenable<String> longestRoom = _longestRoom;

  final ValueNotifier<String> _longestUser = ValueNotifier<String>("");
  late ValueListenable<String> longestUser = _longestUser;

  final ValueNotifier<String> _longestTask = ValueNotifier<String>("");
  late ValueListenable<String> longestTask = _longestTask;

  final ValueNotifier<String> _longestValue = ValueNotifier<String>("");
  late ValueListenable<String> longestValue = _longestValue;

  late final Map<RowType, ValueNotifier<String>>
  rowTypeToLongestStringNotifiers = {
    RowType.date: _longestDate,
    RowType.room: _longestRoom,
    RowType.user: _longestUser,
    RowType.task: _longestTask,
    RowType.value: _longestValue,
  };

  QueryRepository({required Database database}) : _database = database;

  String _intern(RowType rowType, String string) {

    final longestStringNotifier = rowTypeToLongestStringNotifiers[rowType]!;
    if (longestStringNotifier.value.length < string.length) {
      longestStringNotifier.value = string;
    }

    var stringPool = _rowTypeToStringPool[rowType]!;
    stringPool.add(string);
    return stringPool.lookup(string)!;
  }

  Future<void> loadAllRecords() async {
    isLoading.value = true;

    final now = DateTime.now();
    int maxYearsOfData = 7;
    int monthsPerYear = 12;
    int totalMonths = maxYearsOfData * monthsPerYear;
    for (int i = 0; i < totalMonths; i++) {
      final monthDate = DateTime(now.year, now.month - i);
      final List<dynamic> response = await _database.getRecordsForMonth(
        monthDate,
      );
      if (response.isNotEmpty) {
        final newMonthRecords = response.map((m) {
          final value = m['value'];
          final dateTime = DateTime.parse(m['recorded_date']);
          final valueString = value?.toString() ?? '';
          return QueryData(
            date: dateTime,
            dateString: _intern(RowType.date, dateTime.toDisplayString()),
            value: value?.toDouble() ?? double.negativeInfinity,
            valueString: _intern(RowType.value, valueString),
            taskName: _intern(RowType.task, m['task_name']),
            userName: _intern(RowType.user, m['user_name']),
            roomName: _intern(RowType.room, m['room_name']),
          );
        }).toList();
        recordsNotifier.value.addAll(newMonthRecords);
        recordsNotifier.refresh();
      }
    }
    isLoading.value = false;
  }
}

extension DateTimeExtension on DateTime {
  String toDisplayString() {
    DateTime d = toLocal();
    return "${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
  }
}
