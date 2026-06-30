import 'package:animal_room_task_manager/task_lists_management/task_list_management_model.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:flutter/material.dart';

import '../theme_data.dart';
import 'edit_task_list_screen.dart';

/// A screen where the admin can add, edit, or delete task lists
class TaskListManagementScreen extends StatelessWidget {
  final TaskListManagementModel _model;

  const TaskListManagementScreen({super.key, required model}) : _model = model;

  @override
  Widget build(BuildContext context) {
    final taskListMap = _model.taskLists;
    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Scheduler"),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Daily"),
              Tab(text: "Weekly"),
              Tab(text: "Monthly"),
            ],
          ),
        ),
        body: SafeArea(
          child: pad8(
            Column(
              children: [
                Expanded(
                  child: ListenableBuilder(
                    listenable: _model.taskListsListenable,
                    builder: (context, _) {
                      return TabBarView(
                        children: [
                          _buildTaskList(
                            context,
                            taskListMap[TaskFrequency.daily]!,
                          ),
                          _buildTaskList(
                            context,
                            taskListMap[TaskFrequency.weekly]!,
                          ),
                          _buildTaskList(
                            context,
                            taskListMap[TaskFrequency.monthly]!,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                pad8(
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [buildCancelButton(), _buildAddTaskListButton()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(BuildContext context, Set<TaskList> taskLists) {
    return SingleChildScrollView(
      child: Column(
        children: [
          for (final taskList
              in taskLists.toList()
                ..sort((a, b) => a.name.compareTo(b.name))) ...[
            Card(
              elevation: appCardElevation,
              shadowColor: Theme.of(context).primaryColor,
              child: ListTile(
                title: mediumTitleText(context, taskList.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildEditIconButton(context, taskList),
                    _buildDeleteIconButton(context, taskList),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconButton _buildEditIconButton(BuildContext context, TaskList taskList) {
    return IconButton(
      icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
      onPressed: () async {
        await navigate(
          EditTaskListScreen(
            model: _model,
            title: "Edit Task List",
            taskList: taskList,
          ),
        );
      },
    );
  }

  IconButton _buildDeleteIconButton(BuildContext context, TaskList taskList) {
    return IconButton(
      icon: Icon(Icons.delete, color: Theme.of(context).primaryColor),
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

  FilledButton _buildAddTaskListButton() {
    return FilledButton(
      onPressed: () async {
        await navigate(
          EditTaskListScreen(
            model: _model,
            title: "Add New Task List",
            taskList: null,
          ),
        );
      },
      child: Text("Add New Task List"),
    );
  }
}
