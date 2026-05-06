import 'package:flutter/material.dart';
import 'package:material_table_view/material_table_view.dart';
import 'package:material_table_view/table_column_control_handles_popup_route.dart';
import 'package:material_table_view/table_view_typedefs.dart';

import '../theme_data.dart';

class QueryScreen extends StatelessWidget {
  const QueryScreen({super.key});

  @override
  Widget build(BuildContext context) => buildScaffold(
    title: "Query",
    child: const QueryTable(),
    makeScrollable: false,
  );
}

class QueryTable extends StatefulWidget {
  const QueryTable({super.key});

  @override
  State<QueryTable> createState() => _QueryTableState();
}

class _QueryTableState extends State<QueryTable>
    with TickerProviderStateMixin<QueryTable> {
  final selection = <int>{};

  final cellPadding = const EdgeInsets.only(left: 8.0);
  final cellAlignment = Alignment.centerLeft;

  final columns = <_QueryTableColumn>[
    for (int i = 0; i < 1000; i++) _QueryTableColumn(index: i, width: 64.0),
  ];

  double get _rowHeight => 48.0 + 4 * Theme.of(context).visualDensity.vertical;

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
        child: TableView.builder(
          columns: columns,
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
          rowCount: ((1 << 31) - 1),
          rowBuilder: createRowBuilder(context),
          headerBuilder: _headerBuilder,
          headerHeight: _rowHeight,
          bodyContainerBuilder: (context, bodyContainer) => bodyContainer,
        ),
      ),
    );
  }

  Widget _headerBuilder(
    BuildContext context,
    TableRowContentBuilder contentBuilder,
  ) => contentBuilder(context, (context, column) {
    switch (columns[column].index) {
      default:
        return Container(
          decoration: BoxDecoration(
            border: Border(
              right: Divider.createBorderSide(context),
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
                child: Align(
                  alignment: cellAlignment,
                  child: Text('${columns[column].index}'),
                ),
              ),
            ),
          ),
        );
    }
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
        () => columns[index] = columns[index].copyWith(
          translation: newTranslation,
        ),
      ),
      onColumnResize: (index, newWidth) => setState(
        () => columns[index] = columns[index].copyWith(width: newWidth),
      ),
      onColumnMove: (oldIndex, newIndex) =>
          setState(() => columns.insert(newIndex, columns.removeAt(oldIndex))),
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
        var cellIndex = (columns.length * row) + columns[column].index;
        return Padding(
          padding: cellPadding,
          child: _wrapCell(
            cellIndex,
            Align(
              alignment: cellAlignment,
              child: Text(
                '$cellIndex',
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

class _QueryTableColumn extends TableColumn {
  _QueryTableColumn({
    required this.index,
    required super.width,
    super.freezePriority = 0,
    super.sticky = false,
    super.flex = 0,
    super.translation = 0,
    super.minResizeWidth,
    super.maxResizeWidth,
  }) : key = ValueKey<int>(index);

  final int index;

  @override
  final ValueKey<int> key;

  @override
  _QueryTableColumn copyWith({
    double? width,
    int? freezePriority,
    bool? sticky,
    int? flex,
    double? translation,
    double? minResizeWidth,
    double? maxResizeWidth,
  }) => _QueryTableColumn(
    index: index,
    width: width ?? this.width,
    freezePriority: freezePriority ?? this.freezePriority,
    sticky: sticky ?? this.sticky,
    flex: flex ?? this.flex,
    translation: translation ?? this.translation,
    minResizeWidth: minResizeWidth ?? this.minResizeWidth,
    maxResizeWidth: maxResizeWidth ?? this.maxResizeWidth,
  );
}
