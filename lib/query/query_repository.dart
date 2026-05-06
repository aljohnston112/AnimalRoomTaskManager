import 'package:animal_room_task_manager/query/query_model.dart';
import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:flutter/material.dart';

final Map<String, String> _stringPool = {};

String _intern(String source) {
  return _stringPool.putIfAbsent(source, () => source);
}

class QueryRepository {
  final Database _database;

  final RefreshableNotifier<List<QueryData>> recordsNotifier = RefreshableNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(true);

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
          return QueryData(
            date: dateTime,
            dateString: dateTime.toDisplayString(),
            value: value?.toDouble()?? double.negativeInfinity,
            valueString: value?.toString()?? '',
            taskName: _intern(m['task_name']),
            userName: _intern(m['user_name']),
            roomName: _intern(m['room_name']),
          );
        }).toList();
        recordsNotifier.value.addAll(newMonthRecords);
        recordsNotifier.refresh();
      }
    }
    isLoading.value = false;
  }
}

extension on DateTime {
  String toDisplayString() {
    DateTime d = toLocal();
    return "${d.month}/${d.day}/${d.year} ${d.hour}:${d.minute}";
  }
}

