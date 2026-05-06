import 'package:animal_room_task_manager/query/query_model.dart';
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
  final selection = <int>{};

  final cellPadding = const EdgeInsets.only(left: 8.0);
  final cellAlignment = Alignment.centerLeft;

  double get _rowHeight =>
      20.0 + 48.0 + 4 * Theme.of(context).visualDensity.vertical;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: Divider.createBorderSide(context),
            left: Divider.createBorderSide(context),
          ),
        ),
        child: ListenableBuilder(
          listenable: widget._model.records,
          builder: (_, _) {
            return TableView.builder(
              columns: widget._model.columns,
              style: TableViewStyle(
                scrollbars: const TableViewScrollbarsStyle.symmetric(
                  TableViewScrollbarStyle(
                    interactive: true,
                    enabled: TableViewScrollbarEnabled.always,
                    thumbVisibility: WidgetStatePropertyAll(true),
                    trackVisibility: WidgetStatePropertyAll(true),
                  ),
                ),
              ),
              rowHeight: _rowHeight,
              rowCount: widget._model.records.value.length,
              rowBuilder: createRowBuilder(context),
              headerBuilder: _headerBuilder,
              headerHeight: _rowHeight,
              bodyContainerBuilder: (context, bodyContainer) => bodyContainer,
            );
          },
        ),
      ),
    );
  }

  Widget _headerBuilder(
    BuildContext context,
    TableRowContentBuilder contentBuilder,
  ) => contentBuilder(context, (context, column) {
    return Container(
      decoration: BoxDecoration(
        border: Border(right: Divider.createBorderSide(context)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => Navigator.of(
            context,
          ).push(_createColumnControlsRoute(context, column)),
          child: Column(
            children: [
              Padding(
                padding: cellPadding,
                child: Align(
                  alignment: cellAlignment,
                  child: Text(widget._model.columns[column].name),
                ),
              ),
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

  Widget _wrapRow(int index, Widget child) => KeyedSubtree(
    key: ValueKey(index),
    child: DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border(bottom: Divider.createBorderSide(context)),
      ),
      child: child,
    ),
  );

  Widget _wrapCell(int index, Widget child) => KeyedSubtree(
    key: ValueKey(index),
    child: DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border(right: Divider.createBorderSide(context)),
      ),
      child: child,
    ),
  );

  TableRowBuilder createRowBuilder(BuildContext context, [int start = 0]) {
    final theme = Theme.of(context);

    return (context, row, TableRowContentBuilder contentBuilder) {
      row += start;

      final selected = selection.contains(row);

      Widget cellBuilder(BuildContext context, int column) {
        var cellIndex =
            (widget._model.columns.length * row) + column;
        return Padding(
          padding: cellPadding,
          child: _wrapCell(
            cellIndex,
            Align(
              alignment: cellAlignment,
              child: Text(
                widget._model.getRecordAt(column, row),
                overflow: TextOverflow.fade,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ),
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
              selection.clear();
              selection.add(row);
            }),
            child: content,
          ),
        ),
      );
    };
  }
}
