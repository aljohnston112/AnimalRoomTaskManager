import 'package:animal_room_task_manager/task_lists_management/task_list_management_model.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:flutter/material.dart';

import '../theme_data.dart';
import 'add_task_list_screen.dart';

class TaskListManagementScreen extends StatelessWidget {
  final TaskListManagementModel _model;

  const TaskListManagementScreen({super.key, required model}) : _model = model;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Task List Editor",
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ListenableBuilder(
            listenable: _model,
            builder: (context, _) {
              return Center(
                child: constrainToPhoneWidth(
                  ListView(
                    shrinkWrap: true,
                    children: [
                      for (final entry
                          in _model.getTaskLists().entries.toList()..sort(
                            (a, b) => a.key.index.compareTo(b.key.index),
                          )) ...[
                        ExpansionTile(
                          title: mediumTitleText(context, entry.key.toDbString),
                          children: [
                            for (final taskList in entry.value) ...[
                              ListTile(
                                title: mediumTitleText(context, taskList.name),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildEditIconButton(context, taskList),
                                    padding8,
                                    _buildDeleteIconButton(context, taskList),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          padding8,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton(
                onPressed: () async {
                  unNavigate();
                },
                child: Text("Go Back"),
              ),
              FilledButton(
                onPressed: () async {
                  await navigate(
                    AddTaskListPage(
                      model: _model,
                      title: "Add New Task List",
                      taskList: null,
                    ),
                  );
                },
                child: Text("Add New Task List"),
              ),
            ],
          ),
          padding8,
        ],
      ),
    );
  }

  IconButton _buildDeleteIconButton(BuildContext context, TaskList taskList) {
    return IconButton(
      icon: Icon(Icons.delete),
      onPressed: () async {
        _model.deleteTaskList(taskList);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text('Task List deleted'),
            action: SnackBarAction(
              label: 'Undo deletion',
              onPressed: () {
                _model.undeleteTaskList(taskList);
              },
            ),
          ),
        );
      },
    );
  }

  IconButton _buildEditIconButton(BuildContext context, TaskList taskList) {
    return IconButton(
      icon: Icon(Icons.edit),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTaskListPage(
              model: _model,
              title: "Edit Task List",
              taskList: taskList,
            ),
          ),
        );
      },
    );
  }
}
