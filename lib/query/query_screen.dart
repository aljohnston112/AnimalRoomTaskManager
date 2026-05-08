import 'package:animal_room_task_manager/query/query_model.dart';
import 'package:animal_room_task_manager/query/query_repository.dart';
import 'package:flutter/material.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:material_table_view/table_column_control_handles_popup_route.dart';
import 'package:material_table_view/table_view_typedefs.dart';
import 'package:provider/provider.dart';

import '../theme_data.dart';

class QueryScreen extends StatelessWidget {
  const QueryScreen({super.key});

  @override
  Widget build(BuildContext context) => buildScaffold(
    title: "Query",
    child: Column(
      children: [
        Expanded(
          child: QueryTable(model: QueryModel(queryRepository: context.read())),
        ),
        padding8,
        FilledButton(onPressed: () => unNavigate(), child: Text("Go Back")),
      ],
    ),
    makeScrollable: false,
  );
}

class QueryTable extends StatefulWidget {
  final QueryModel _model;

  const QueryTable({super.key, required QueryModel model}) : _model = model;

  @override
  State<QueryTable> createState() => _QueryTableState();
}

class _QueryTableState extends State<QueryTable>
    with TickerProviderStateMixin<QueryTable> {
  final cellAlignment = Alignment.centerLeft;

  int? selectedRow;
  DateTime? _startDate;
  DateTime? _endDate;

  double get _headerHeight =>
      109.0 + 16 * Theme.of(context).visualDensity.vertical;

  final _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: Divider.createBorderSide(context),
            left: Divider.createBorderSide(context),
            right: Divider.createBorderSide(context),
          ),
        ),
        child: ListenableBuilder(
          listenable: widget._model.records,
          builder: (_, _) {
            return Column(
              children: [
                Wrap(
                  children: [
                    constrainTextBoxWidth(
                      Column(
                        children: [
                          ListTile(
                            title: Text(
                              "From: ${_startDate?.toLocal().toDisplayString() ?? 'Select'}",
                            ),
                            trailing: Icon(Icons.calendar_today),
                            onTap: () => _pickDate(isStart: true),
                          ),
                          ListTile(
                            title: Text(
                              "To: ${_endDate?.toLocal().toDisplayString() ?? 'Select'}",
                            ),
                            trailing: Icon(Icons.calendar_today),
                            onTap: () => _pickDate(isStart: false),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            child: Text("Apply Filter"),
                          ),
                        ],
                      ),
                    ),
                    constrainTextBoxWidth(
                      TextField(
                        controller: _textEditingController,
                        decoration: InputDecoration(
                          hintText: 'Search values',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () => _textEditingController.clear(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // final double totalWidth = constraints.maxWidth;
                      // final int columnCount = widget._model.columns.length;
                      // final double columnWidth = totalWidth / columnCount;
                      // final padding = widget._model.cellPadding.horizontal;
                      // final lines =
                      //     (widget._model.getMaxStringLength() *
                      //             estimatedCharacterWidth /
                      //             (columnWidth - padding))
                      //         .ceil();
                      // final rowHeight = (lines * estimatedLineHeight) + padding;
                      return ListenableBuilder(
                        listenable: widget._model.longestStringListenable,
                        builder: (_, _) {
                          return TableView.builder(
                            columns: widget._model.getNewColumns(DefaultTextStyle.of(context)),
                            style: TableViewStyle(
                              scrollbars:
                                  const TableViewScrollbarsStyle.symmetric(
                                    TableViewScrollbarStyle(
                                      interactive: true,
                                      enabled: TableViewScrollbarEnabled.always,
                                      thumbVisibility: WidgetStatePropertyAll(
                                        true,
                                      ),
                                      trackVisibility: WidgetStatePropertyAll(
                                        true,
                                      ),
                                    ),
                                  ),
                            ),
                            rowHeight: estimatedLineHeight,
                            rowCount: widget._model.records.value.length,
                            rowBuilder: createRowBuilder(context),
                            headerBuilder: _headerBuilder,
                            headerHeight: _headerHeight,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final DateTime initial =
        (isStart ? _startDate : _endDate) ?? DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(DateTime.now().year - 7),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _startDate!.isAfter(_endDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _endDate!.isBefore(_startDate!)) {
            _startDate = null;
          }
        }
      });
    }
  }

  Widget _headerBuilder(
    BuildContext context,
    TableRowContentBuilder contentBuilder,
  ) => contentBuilder(context, (context, column) {
    var columnName = widget._model.columns[column].name;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: Divider.createBorderSide(context),
          top: Divider.createBorderSide(context),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => Navigator.of(
            context,
          ).push(_createColumnControlsRoute(context, column)),
          child: Padding(
            padding: cellPadding,
            child: Column(
              children: [
                Align(alignment: cellAlignment, child: Text(columnName)),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        widget._model.sortColumn(column, isUp: true);
                      },
                      icon: Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      onPressed: () {
                        widget._model.sortColumn(column, isUp: false);
                      },
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  });

  ModalRoute<void> _createColumnControlsRoute(
    BuildContext cellBuildContext,
    int columnIndex,
  ) {
    return TableColumnControlHandlesPopupRoute.realtime(
      controlCellBuildContext: cellBuildContext,
      columnIndex: columnIndex,
      tableViewChanged: null,
      onColumnTranslate: (index, newTranslation) => setState(
        () => widget._model.columns[index] = widget._model.columns[index]
            .copyWith(translation: newTranslation),
      ),
      onColumnResize: (index, newWidth) => setState(
        () => widget._model.columns[index] = widget._model.columns[index]
            .copyWith(width: newWidth),
      ),
      onColumnMove: (oldIndex, newIndex) => setState(
        () => widget._model.columns.insert(
          newIndex,
          widget._model.columns.removeAt(oldIndex),
        ),
      ),
    );
  }

  Widget _wrapRow(int index, Widget child) =>
      KeyedSubtree(key: ValueKey(index), child: child);

  Widget _wrapCell(int index, Widget child) => KeyedSubtree(
    key: ValueKey(index),
    child: DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border(
          right: Divider.createBorderSide(context),
          bottom: Divider.createBorderSide(context),
        ),
      ),
      child: Padding(padding: cellPadding, child: child),
    ),
  );

  TableRowBuilder createRowBuilder(BuildContext context, [int start = 0]) {
    final theme = Theme.of(context);

    return (context, row, TableRowContentBuilder contentBuilder) {
      row += start;

      final selected = selectedRow == row;

      Widget cellBuilder(BuildContext context, int column) {
        var cellIndex = (widget._model.columns.length * row) + column;
        return _wrapCell(
          cellIndex,
          Text(widget._model.getRecordAt(column, row)),
        );
      }

      var content = contentBuilder(context, cellBuilder);
      return _wrapRow(
        row,
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: theme.colorScheme.primaryContainer.withAlpha(
            selected ? 0xFF : 0,
          ),
          child: InkWell(
            onTap: () => setState(() {
              selectedRow = row;
            }),
            child: content,
          ),
        ),
      );
    };
  }
}
