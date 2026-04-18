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
      child: ConstrainedBox(
        // To prevent the list from taking up the full width of a wide screen
        constraints: const BoxConstraints(maxWidth: widePhoneWidth),
        child: ListenableBuilder(
          listenable: roomCheckModel,
          builder: (context, _) {
            return ListView(
              shrinkWrap: true,
              // A card per task record
              children: roomCheckModel.getTaskEntries().map((record) {
                return _buildTaskCard(context, roomCheckModel, record);
              }).toList(),
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
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxTextFieldWidth),
          child: _buildNumberEntryField(entry, task),
        ),
      ] else ...[
        _buildTaskCompleteWidget(entry, context),
      ],

      // The add comment button or comment field
      if (roomCheckModel.shouldCommentBeDisplayedForTask(task)) ...[
        // Only show the field if there is a comment or
        // the task has already been recorded
        if (roomCheckModel.getCommentController(task).text.isNotEmpty ||
            !roomCheckModel.isTaskRecorded(task)) ...[
          padding8,
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxTextFieldWidth),
            child: _buildCommentInput(entry),
          ),
          padding8,
        ],
      ] else ...[
        padding8,
        FilledButton(
          child: Text("Add Comment"),
          onPressed: () {
            roomCheckModel.onAddCommentClicked(task);
          },
        ),
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

  TextField _buildCommentInput(TaskEntryModel entry) {
    var taskUnrecorded = entry.record == null;
    return TextField(
      // Can't overwrite submitted comments
      enabled: taskUnrecorded,
      keyboardType: TextInputType.multiline,
      controller: roomCheckModel.getCommentController(entry.task),
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

  void _validate() {
    final value = double.tryParse(widget.controller.text);
    if (value == null) {
      setState(() {
        _errorText = null;
      });
    } else {
      for (final range in widget.task.ranges) {
        if (value < range.min || value > range.max) {
          if (range.isRequired) {
            setState(() {
              _errorText =
                  'Value must be between '
                  '(${range.min} to ${range.max})';
            });
            break;
          } else {
            setState(() {
              _errorText =
                  'Value out of range '
                  '(${range.min} to ${range.max})';
            });
          }
        } else {
          setState(() {
            _errorText = null;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var taskUnrecorded = widget.entry.record == null;
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
      decoration: buildInputDecoration(
        widget.task.ranges.first.units,
      ).copyWith(errorText: _errorText),
    );
  }
}
