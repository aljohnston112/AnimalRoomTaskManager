import 'package:animal_room_task_manager/room_check/room_check_model.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme_data.dart';

/// This screen lays out a list of tasks for a given room check,
/// allows the user to enter data required by the tasks and
/// mark the tasks as complete,
/// and submit any entered data and tasks completed as a final record.
class RoomCheckScreen extends StatelessWidget {
  final RoomCheckModel roomCheckModel;

  const RoomCheckScreen({super.key, required this.roomCheckModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: roomCheckModel,
      builder: (context, _) {
        return Column(
          children: [padding8, ..._buildRoomCheckScreen(context), padding8],
        );
      },
    );
  }

  List<Widget> _buildRoomCheckScreen(BuildContext context) {
    return [
      _buildTaskListTitle(context),
      _buildTaskList(),
      _buildSubmitButton(),
    ];
  }

  Text _buildTaskListTitle(BuildContext context) {
    return Text(roomCheckModel.taskList.name, style: largeTileTheme(context));
  }

  Widget _buildTaskList() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          padding8,
          // To stop the task list from having an unbounded height
          Expanded(child: TaskListWidget(roomCheckModel: roomCheckModel)),
          padding8,
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return FilledButton(
      onPressed: () {
        roomCheckModel.submit();
      },
      child: Text("Submit"),
    );
  }
}

class TaskListWidget extends StatelessWidget {
  final RoomCheckModel roomCheckModel;

  const TaskListWidget({super.key, required this.roomCheckModel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        // To prevent the list from taking up the full width of a wide screen
        constraints: const BoxConstraints(maxWidth: widePhoneWidth),
        child: ListView(
          shrinkWrap: true,
          // A card per task
          children: [
            ...roomCheckModel.getTaskRecord.map((record) {
              return _buildTaskCard(record, context);
            }),
          ],
        ),
      ),
    );
  }

  Card _buildTaskCard(TaskEntry record, BuildContext context) {
    return Card(
      child: Padding(
        padding: insets8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaskDescription(record, context),
            ..._buildTaskEntryForm(record, context),
          ],
        ),
      ),
    );
  }

  Text _buildTaskDescription(TaskEntry record, BuildContext context) {
    return Text(record.task.description, style: mediumTileTheme(context));
  }

  List<Widget> _buildTaskEntryForm(TaskEntry entry, BuildContext context) {
    var task = entry.task;
    return [
      if (task is QuantitativeTask) ...[
        // To keep the input box from being super wide
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxTextFieldWidth),
          child: _buildNumberEntryField(entry, task),
        ),
      ] else ...[
        _buildTaskCompleteWidget(entry, context),
      ],
      if (roomCheckModel.hasComment(task)) ...[
        padding8,
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxTextFieldWidth),
          child: _buildCommentInput(entry),
        ),
        padding8
      ] else ...[
        padding8,
        FilledButton(
          child: Text("Add Comment"),
          onPressed: () {
            roomCheckModel.addCommentField(task);
          },
        ),
      ],
    ];
  }

  TextField _buildNumberEntryField(
    TaskEntry entry,
    QuantitativeTask<dynamic> task,
  ) {
    return TextField(
      // Can't overwrite submitted numbers
      enabled: entry.record == null,
      controller: roomCheckModel.getValueController(task),
      keyboardType: TextInputType.numberWithOptions(
        signed: false,
        decimal: true,
      ),
      // To enforce only decimal numbers
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: buildInputDecoration(task.range.units)
    );
  }

  Row _buildTaskCompleteWidget(TaskEntry entry, BuildContext context) {
    return Row(
      children: [
        _buildTaskCompleteCheckBox(entry),
        Text("Task Completed", style: smallTileTheme(context)),
      ],
    );
  }

  Checkbox _buildTaskCompleteCheckBox(TaskEntry entry) {
    var task = entry.task;
    return Checkbox(
      value: roomCheckModel.isTaskCompleted(task),
      onChanged: entry.record != null
          ? null // Cannot unmark a completed task
          : (val) => roomCheckModel.toggleTask(task, val),
    );
  }

  TextField _buildCommentInput(TaskEntry entry) {
    return TextField(
      // Can't overwrite submitted comments
      enabled: entry.record == null,
      keyboardType: TextInputType.multiline,
      controller: roomCheckModel.getCommentController(entry.task),
      // No limit
      maxLines: null,
      decoration: buildInputDecoration("Comment"),
    );
  }
  
}
