import 'dart:math';

import 'package:animal_room_task_manager/query/query_model.dart';
import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:flutter/material.dart';

final Set<String> _stringPool = {};

String _intern(String string) {
  _stringPool.add(string);
  return _stringPool.lookup(string)!;
}

class QueryRepository {
  final Database _database;

  final RefreshableNotifier<List<QueryData>> recordsNotifier =
      RefreshableNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(true);

  // Date is length 16
  var _longestStringLength = 16;

  int get longestStringLength => _longestStringLength;

  QueryRepository({required Database database}) : _database = database;

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
          var value = m['value'];
          var dateTime = DateTime.parse(m['recorded_date']);
          var valueString = value?.toString() ?? '';
          _longestStringLength = max(_longestStringLength, valueString.length);
          return QueryData(
            date: dateTime,
            dateString: dateTime.toDisplayString(),
            value: value?.toDouble() ?? double.negativeInfinity,
            valueString: valueString,
            taskName: _intern(m['task_name']),
            userName: _intern(m['user_name']),
            roomName: _intern(m['room_name']),
          );
        }).toList();
        recordsNotifier.value.addAll(newMonthRecords);
        for (final s in _stringPool) {
          _longestStringLength = max(_longestStringLength, s.length);
        }
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
