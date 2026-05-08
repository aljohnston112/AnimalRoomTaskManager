import 'package:animal_room_task_manager/query/query_model.dart';
import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:flutter/foundation.dart';

enum RowType {
  date("Record Date"),
  room("Room Name"),
  user("User Name"),
  task("Task"),
  value("Recorded Value");

  final String columnName;

  const RowType(this.columnName);
}

final Map<RowType, Set<String>> _rowTypeToStringPool = {
  for (var type in RowType.values) type: {},
};

List<String> getSortedStringPoolForType(RowType rowType) {
  final pool = _rowTypeToStringPool[rowType] ?? {};
  return pool.toList()..sort();
}

class QueryRepository {
  final Database _database;

  final RefreshableNotifier<List<QueryData>> recordsNotifier =
      RefreshableNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(true);

  final Map<RowType, ValueNotifier<String>> _rowTypeToLongestStringNotifiers = {
    for (var type in RowType.values) type: ValueNotifier<String>(""),
  };

  late final Map<RowType, ValueListenable<String>>
  rowTypeToLongestStringListenables = Map.unmodifiable(
    _rowTypeToLongestStringNotifiers,
  );

  QueryRepository({required Database database}) : _database = database;

  String _intern(RowType rowType, String string) {
    final longestStringNotifier = _rowTypeToLongestStringNotifiers[rowType]!;
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
    return "${d.month.toString().padLeft(2, '0')}/"
        "${d.day.toString().padLeft(2, '0')}/"
        "${d.year} ${d.hour.toString().padLeft(2, '0')}:"
        "${d.minute.toString().padLeft(2, '0')}";
  }
}
