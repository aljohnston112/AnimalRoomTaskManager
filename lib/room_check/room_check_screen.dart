import 'package:animal_room_task_manager/main.dart';
import 'package:animal_room_task_manager/room_check/room_check_model.dart';
import 'package:animal_room_task_manager/room_check/task_list_widget.dart';
import 'package:flutter/material.dart';

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
    return buildScaffold(
      title: roomCheckModel.taskList.name,
      child: Column(
        children: [
          _buildTaskList(),
          _buildCancelSubmitButtons(context),
          padding8,
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    // Expanded needed since this is nested in a Column
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // To stop the task list from having an unbounded height
          Expanded(child: TaskListWidget(roomCheckModel: roomCheckModel)),
          padding8,
        ],
      ),
    );
  }

  Widget _buildCancelSubmitButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton(
          child: Text("Cancel"),
          onPressed: () async {
            // Go back only after user has confirmed they want to cancel
            await showDialog<bool>(
              context: context,
              builder: (context) => buildCancelConfirmationDialog(context),
            ).then((result) {
              if (result == true) {
                navigatorKey.currentState?.pop();
              }
            });
          },
        ),
        padding16,
        FilledButton(
          child: Text("Submit"),
          onPressed: () async {
            if (!roomCheckModel.submit()) {
              if (context.mounted) {
                showSnackBar(
                  context,
                  "Some tasks were already done, "
                      "so not all tasks have been attributed to you. "
                      "All other tasks have been recorded",
                );
              }
            }
            if (roomCheckModel.hasUnsavedComments()) {
              // If there are comments on uncompleted tasks,
              // they will not be saved,
              // so the user has to confirm their deletion
              await showDialog<bool>(
                context: context,
                builder: (context) => buildUnsavedCommentsDialog(context),
              ).then((result) {
                if (result == true) {
                  navigatorKey.currentState?.pop();
                }
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }

  AlertDialog buildCancelConfirmationDialog(BuildContext context) {
    return AlertDialog(
      title: Text('Confirm Cancellation'),
      content: Text('Are you sure you want to lose your progress?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Yes'),
        ),
      ],
    );
  }

  AlertDialog buildUnsavedCommentsDialog(BuildContext context) {
    return AlertDialog(
      title: Text('Confirm Losing Progress'),
      content: Text(
        'Are you sure you want to lose your comments on uncompleted tasks?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Yes'),
        ),
      ],
    );
  }
}
