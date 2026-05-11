import 'package:animal_room_task_manager/room_check/record_repository.dart';
import 'package:animal_room_task_manager/room_check/room_check_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../task_lists_management/task_list_repository.dart';
import '../theme_data.dart';

/// A list of tasks for the room check screen
class TaskListWidget extends StatelessWidget {
  final RoomCheckModel roomCheckModel;

  const TaskListWidget({super.key, required this.roomCheckModel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: constrainToPhoneWidth(
        ListenableBuilder(
          listenable: roomCheckModel,
          builder: (context, _) {
            var taskEntries = roomCheckModel.getTaskEntries();
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    // A card per task record
                    children: taskEntries.map((record) {
                      return _buildTaskCard(context, roomCheckModel, record);
                    }).toList(),
                  ),
                ),
                if (roomCheckModel.getCommentController().text.isNotEmpty ||
                    roomCheckModel.shouldCommentBeDisplayed()) ...[
                  padding8,
                  constrainTextBoxWidth(
                    _buildCommentInput(roomCheckModel.getSavedComment() ?? ""),
                  ),
                  padding8,
                ] else ...[
                  padding8,
                  FilledButton(
                    child: Text("Add Comment"),
                    onPressed: () {
                      roomCheckModel.onAddCommentClicked();
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Card _buildTaskCard(
    BuildContext context,
    RoomCheckModel roomCheckModel,
    TaskEntryModel taskEntry,
  ) {
    return Card(
      child: Padding(
        padding: insets8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            mediumTitleText(context, taskEntry.task.description),
            ..._buildTaskCardEntryForm(context, roomCheckModel, taskEntry),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTaskCardEntryForm(
    BuildContext context,
    RoomCheckModel roomCheckModel,
    TaskEntryModel entry,
  ) {
    var task = entry.task;
    return [
      // The number field or checkbox
      if (task is QuantitativeTask) ...[
        // To keep the input box from being super wide
        constrainTextBoxWidth(_buildNumberEntryField(entry, task)),
      ] else ...[
        _buildTaskCompleteWidget(entry, context),
      ],
    ];
  }

  Widget _buildNumberEntryField(
    TaskEntryModel entry,
    QuantitativeTask<dynamic> task,
  ) {
    return NumberEntryField(
      controller: roomCheckModel.getQuantitativeValueController(task),
      entry: entry,
      task: task,
    );
  }

  Row _buildTaskCompleteWidget(TaskEntryModel entry, BuildContext context) {
    return Row(
      children: [
        _buildTaskCompleteCheckBox(entry),
        smallTitleText(context, "Task Completed"),
      ],
    );
  }

  Checkbox _buildTaskCompleteCheckBox(TaskEntryModel entry) {
    var task = entry.task;
    var taskRecorded = entry.record != null;
    return Checkbox(
      value: roomCheckModel.isTaskCompleted(task),
      onChanged: taskRecorded
          ? null // Cannot unmark a completed task
          : (val) => roomCheckModel.toggleTaskCompletion(task, val),
    );
  }

  TextField _buildCommentInput(String comment) {
    return TextField(
      // Can't overwrite submitted comments
      enabled: comment.isEmpty,
      keyboardType: TextInputType.multiline,
      controller: roomCheckModel.getCommentController(),
      // No limit
      maxLines: null,
      decoration: buildInputDecoration("Comment"),
    );
  }
}

class NumberEntryField extends StatefulWidget {
  final TextEditingController controller;
  final TaskEntryModel entry;
  final QuantitativeTask<dynamic> task;

  const NumberEntryField({
    required this.controller,
    required this.entry,
    required this.task,
    super.key,
  });

  @override
  State<NumberEntryField> createState() => _NumberEntryFieldState();
}

class _NumberEntryFieldState extends State<NumberEntryField> {
  String? _errorText;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validate);
    super.dispose();
  }

  void _validate() {
    if (!mounted) {
      return;
    }
    final value = double.tryParse(widget.controller.text);
    if (value == null) {
      setState(() {
        _errorText = null;
      });
    } else if (!widget.entry.isCompleted) {
      final warningRange = widget.task.warningRange;
      final requiredRange = widget.task.requiredRange;
      if (requiredRange != null &&
          (value < requiredRange.min || value > requiredRange.max)) {
        setState(() {
          _errorText =
              'Value must be between '
              '(${requiredRange.min} to ${requiredRange.max})';
        });
      } else if (warningRange != null &&
          (value < warningRange.min || value > warningRange.max)) {
        setState(() {
          _errorText =
              'Value out of range '
              '(${warningRange.min} to ${warningRange.max})';
        });
      } else {
        setState(() {
          _errorText = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var taskUnrecorded = widget.entry.record == null;
    String units;
    final warningRange = widget.task.warningRange;
    final requiredRange = widget.task.requiredRange;
    if (warningRange != null) {
      units = warningRange.units;
    } else if (requiredRange != null) {
      units = requiredRange.units;
    } else {
      units = '';
    }
    final record = widget.entry.record;
    if (record is QuantitativeRecord) {
      widget.controller.text = record.recordedValue.toString();
    }
    return TextField(
      enabled: taskUnrecorded,
      controller: widget.controller,
      keyboardType: const TextInputType.numberWithOptions(
        signed: false,
        decimal: true,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: buildInputDecoration(units).copyWith(errorText: _errorText),
    );
  }
}
