import 'package:animal_room_task_manager/query/query_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:material_table_view/src/table_column.dart';

class QueryData {
  final DateTime date;
  final String dateString;
  final double value;
  final String valueString;
  final String taskName;
  final String userName;
  final String roomName;

  QueryData({
    required this.dateString,
    required this.value,
    required this.valueString,
    required this.taskName,
    required this.userName,
    required this.roomName,
    required this.date,
  });
}

class RefreshableNotifier<T> extends ValueNotifier<T> {
  RefreshableNotifier(super.value);

  void refresh() => notifyListeners();
}

class QueryModel {
  static const List<String> columnNames = [
    "Record Date",
    "Room Name",
    "User Name",
    "Task",
    "Recorded Value",
  ];

  final QueryRepository _repository;
  late final RefreshableNotifier<List<QueryData>> records;
  late final ValueNotifier<bool> isLoading;
  late List<QueryTableColumn> columns;

  QueryModel(
      {required QueryRepository queryRepository})
      : _repository = queryRepository {
    queryRepository.loadAllRecords();
    isLoading = queryRepository.isLoading;
    records = queryRepository.recordsNotifier;
    columns = _getColumns();
  }

  List<QueryTableColumn> _getColumns() {
    var i = 0;
    return [
      for (final columnName in columnNames)
        QueryTableColumn(name: columnName, index: i++, width: 50, flex: 1),
    ];
  }

  int getMaxStringLength() {
    return _repository.longestStringLength;
  }

  String getColumnFromRecord<T>(QueryData query, int columnIndex) {
    switch (columnIndex) {
      case 0:
        return query.dateString;
      case 1:
        return query.roomName;
      case 2:
        return query.userName;
      case 3:
        return query.taskName;
      case 4:
        return query.valueString;
      default:
        throw Exception("Column out of range");
    }
  }

  dynamic getSortColumnFromRecord<T>(QueryData query, int columnIndex) {
    switch (columnIndex) {
      case 0:
        return query.date;
      case 1:
        return query.roomName;
      case 2:
        return query.userName;
      case 3:
        return query.taskName;
      case 4:
        return query.value;
      default:
        throw Exception("Column out of range");
    }
  }

  String getRecordAt(int columnIndex, int rowIndex) {
    if (rowIndex >= 0 && rowIndex < records.value.length) {
      return getColumnFromRecord(records.value[rowIndex], columnIndex);
    }
    return '';
  }

  void sortColumn(int column, {required bool isUp}) {
    final multiplier = isUp ? 1 : -1;
    mergeSort<QueryData>(
      records.value,
      compare: (q1, q2) {
        return Comparable.compare(
          getSortColumnFromRecord(q1, column),
          getSortColumnFromRecord(q2, column),
        ) *
            multiplier;
      },
    );
    records.refresh();
  }

  void applyDateFilter(DateTime start, DateTime end) {
    // TODO
  }
}

class QueryTableColumn extends TableColumn {
  QueryTableColumn({
    required this.index,
    required this.name,
    required super.width,
    super.freezePriority = 0,
    super.sticky = false,
    super.flex = 0,
    super.translation = 0,
    super.minResizeWidth,
    super.maxResizeWidth,
  }) : key = ValueKey<int>(index);

  final int index;
  final String name;

  @override
  final ValueKey<int> key;

  @override
  QueryTableColumn copyWith({
    double? width,
    int? freezePriority,
    bool? sticky,
    int? flex,
    double? translation,
    double? minResizeWidth,
    double? maxResizeWidth,
  }) =>
      QueryTableColumn(
        index: index,
        name: name,
        width: width ?? this.width,
        freezePriority: freezePriority ?? this.freezePriority,
        sticky: sticky ?? this.sticky,
        flex: flex ?? this.flex,
        translation: translation ?? this.translation,
        minResizeWidth: minResizeWidth ?? this.minResizeWidth,
        maxResizeWidth: maxResizeWidth ?? this.maxResizeWidth,
      );
}
