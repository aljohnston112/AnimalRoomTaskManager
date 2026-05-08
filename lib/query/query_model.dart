import 'dart:math';

import 'package:animal_room_task_manager/query/query_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_table_view/material_table_view.dart' show TableColumn;

final cellPadding = const EdgeInsetsGeometry.all(8);
final double estimatedLineHeight = 20.0 + cellPadding.horizontal;

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

  dynamic getRowAsValue(RowType rowType) {
    return switch (rowType) {
      RowType.date => date,
      RowType.room => roomName,
      RowType.user => userName,
      RowType.task => taskName,
      RowType.value => value,
    };
  }

  String getRowAsDisplayString(RowType rowType) {
    return switch (rowType) {
      RowType.date => dateString,
      RowType.room => roomName,
      RowType.user => userName,
      RowType.task => taskName,
      RowType.value => valueString,
    };
  }
}

class RefreshableNotifier<T> extends ValueNotifier<T> {
  RefreshableNotifier(super.value);

  void refresh() => notifyListeners();
}

class QueryModel {

  final QueryRepository _repository;
  late final Listenable longestStringListenable = Listenable.merge(
    _repository.rowTypeToLongestStringListenables.values,
  );

  late final Map<RowType, ValueListenable<String>> rowTypeToLongestString =
      _repository.rowTypeToLongestStringListenables;

  late final RefreshableNotifier<List<QueryData>> records;
  late final ValueNotifier<bool> isLoading;
  late List<QueryTableColumn> columns;

  QueryModel({required QueryRepository queryRepository})
    : _repository = queryRepository {
    queryRepository.loadAllRecords();
    isLoading = queryRepository.isLoading;
    records = queryRepository.recordsNotifier;
  }

  double calculatePixelWidth(DefaultTextStyle textStyle, String text) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle.style),
      textDirection: TextDirection.ltr,
    )..layout();
    // + 1 is needed to prevent overflow; ceil did not prevent it
    return textPainter.width + cellPadding.horizontal + 1;
  }

  static final sortingArrowsWidth = 97.0;

  List<QueryTableColumn> getNewColumns(DefaultTextStyle textStyle) {
    var i = 0;
    columns = RowType.values.map((v) {
      final rowType = v;
      final columnName = v.columnName;
      final minWidth = max(
        calculatePixelWidth(textStyle, columnName),
        sortingArrowsWidth,
      );
      final width = max(
        calculatePixelWidth(textStyle, rowTypeToLongestString[rowType]!.value),
        minWidth,
      );
      return QueryTableColumn(
        name: columnName,
        index: i++,
        minResizeWidth: minWidth,
        width: width,
      );
    }).toList();
    return columns;
  }

  String getRecordAt(int columnIndex, int rowIndex) {
    if (rowIndex >= 0 && rowIndex < records.value.length) {
      final rowType = RowType.values[columnIndex];
      return records.value[rowIndex].getRowAsDisplayString(rowType);
    }
    return '';
  }

  void sortColumn(int columnIndex, {required bool isUp}) {
    final rowType = RowType.values[columnIndex];
    final multiplier = isUp ? 1 : -1;
    mergeSort<QueryData>(
      records.value,
      compare: (q1, q2) {
        return Comparable.compare(
              q1.getRowAsValue(rowType),
              q2.getRowAsValue(rowType),
            ) *
            multiplier;
      },
    );
    records.refresh();
  }

  List<String> getFilterOptionsForColumn(RowType rowType) {
    return getSortedStringPoolForType(rowType);
  }

  void applyDateFilter(DateTime start, DateTime end) {
    // TODO
  }

  void toggleFilter(RowType rowType, String filterString, bool add) {

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
  }) => QueryTableColumn(
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
