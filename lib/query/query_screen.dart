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
  static const arrowHeight = 41;
  final _headerHeight = arrowHeight + estimatedLineHeight;
  final cellAlignment = Alignment.centerLeft;

  int? selectedRow;

  DateTime? _startDate;
  DateTime? _endDate;

  final TextEditingController _minValueController = TextEditingController();
  final TextEditingController _maxValueController = TextEditingController();

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
                ListenableBuilder(
                  listenable: widget._model.isLoading,
                  builder: (_, _) {
                    if (widget._model.isLoading.value == true) {
                      return const Center(
                        child: Column(
                          children: [
                            padding8,
                            CircularProgressIndicator(),
                            padding8,
                          ],
                        ),
                      );
                    } else {
                      return Wrap(
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          constrainTextBoxWidth(
                            Column(
                              children: [
                                padding8,
                                ListTile(
                                  title: Text(
                                    "From: ${_startDate?.toLocal().toDisplayString() ?? 'Select'}",
                                  ),
                                  trailing: Icon(Icons.calendar_today),
                                  onTap: () => _pickDate(isStart: true),
                                ),
                                padding8,
                                ListTile(
                                  title: Text(
                                    "To: ${_endDate?.toLocal().toDisplayString() ?? 'Select'}",
                                  ),
                                  trailing: Icon(Icons.calendar_today),
                                  onTap: () => _pickDate(isStart: false),
                                ),
                                padding8,
                                FilledButton(
                                  onPressed: () {
                                    widget._model.applyRangeFilter(
                                      RowType.date,
                                      _startDate,
                                      _endDate,
                                    );
                                  },
                                  child: Text("Apply Filter"),
                                ),
                                padding8,
                              ],
                            ),
                          ),

                          padding8,
                          Column(
                            children: [
                              FilledButton(
                                onPressed: () {
                                  _showFilterPopup(RowType.room);
                                },
                                child: Text("Open Room Filter"),
                              ),
                              padding8,
                              FilledButton(
                                onPressed: () {
                                  _showFilterPopup(RowType.user);
                                },
                                child: Text("Open User Filter"),
                              ),
                              padding8,
                              FilledButton(
                                onPressed: () {
                                  _showFilterPopup(RowType.task);
                                },
                                child: Text("Open Task Filter"),
                              ),
                              padding8,
                            ],
                          ),
                          padding8,

                          constrainTextBoxWidth(
                            Column(
                              children: [
                                padding8,
                                TextFormField(
                                  controller: _minValueController,
                                  decoration: const InputDecoration(
                                    labelText: "Minimum Value",
                                    hintText: "-inf",
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                                padding8,
                                TextFormField(
                                  controller: _maxValueController,
                                  decoration: const InputDecoration(
                                    labelText: "Maximum Value",
                                    hintText: "inf",
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                                padding8,
                                FilledButton(
                                  onPressed: () {
                                    widget._model.applyRangeFilter(
                                      RowType.value,
                                      double.parse(_minValueController.text),
                                        double.parse(_maxValueController.text),
                                    );
                                  },
                                  child: const Text("Apply Value Filter"),
                                ),
                                padding8,
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return ListenableBuilder(
                        listenable: widget._model.longestStringListenable,
                        builder: (_, _) {
                          return TableView.builder(
                            columns: widget._model.getNewColumns(
                              DefaultTextStyle.of(context),
                            ),
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

  Future<void> _showFilterPopup(RowType rowType) async {
    var model = widget._model;
    final options = getSortedStringPoolForType(rowType);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Filter ${rowType.name}"),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.75,
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsetsGeometry.all(64),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            return ListenableBuilder(
                              listenable:
                                  widget._model.currentFilters[rowType]!,
                              builder: (context, _) {
                                final currentFilter = widget
                                    ._model
                                    .currentFilters[rowType]!
                                    .value;
                                var option = options[index];
                                return CheckboxListTile(
                                  title: Text(option),
                                  value: currentFilter.contains(option),
                                  onChanged: (bool? isChecked) {
                                    model.toggleFilter(
                                      rowType,
                                      option,
                                      isChecked ?? false,
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                      padding8,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FilledButton(
                            onPressed: () {
                              model.addAllFiltersForRow(rowType);
                            },
                            child: const Text("Add All"),
                          ),
                          padding8,
                          FilledButton(
                            onPressed: () {
                              model.clearAllFiltersForRow(rowType);
                            },
                            child: const Text("Clear All"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Done"),
          ),
        ],
      ),
    );
    widget._model.updateRecords();
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
        // child: InkWell(
        //   onTap: () => Navigator.of(
        //     context,
        //   ).push(_createColumnControlsRoute(context, column)),
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
      // ),
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

  @override
  void dispose() {
    _minValueController.dispose();
    _maxValueController.dispose();
    super.dispose();
  }
}
