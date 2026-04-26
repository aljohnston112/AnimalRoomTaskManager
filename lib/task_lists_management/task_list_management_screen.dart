import 'package:animal_room_task_manager/task_lists_management/task_list_management_model.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:flutter/material.dart';

import '../theme_data.dart';

class TaskListManagementScreen extends StatelessWidget {
  final TaskListManagementModel _model;

  const TaskListManagementScreen({super.key, model}) : _model = model;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Task List Editor",
      child: Center(
        child: constrainToPhoneWidth(
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ListenableBuilder(
                listenable: _model,
                builder: (context, _) {
                  return Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final entry
                            in _model.getTaskLists().entries.toList()..sort(
                              (a, b) => a.key.index.compareTo(b.key.index),
                            )) ...[
                          ExpansionTile(
                            title: mediumTitleText(
                              context,
                              entry.key.toDbString,
                            ),
                            children: [
                              for (final taskList in entry.value) ...[
                                ListTile(
                                  title: mediumTitleText(
                                    context,
                                    taskList.name,
                                  ),
                                  trailing: _buildDeleteIconButton(
                                    context,
                                    taskList,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              padding8,
              FilledButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddTaskListPage(model: _model),
                    ),
                  );
                },
                child: mediumTitleText(context, "Add New Task List"),
              ),
              padding8,
            ],
          ),
        ),
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
                _model.undeleteTaskList(taskList.name);
              },
            ),
          ),
        );
      },
    );
  }
}

class AddTaskListPage extends StatefulWidget {
  final TaskListManagementModel _model;

  const AddTaskListPage({super.key, required TaskListManagementModel model})
    : _model = model;

  @override
  State<StatefulWidget> createState() {
    return AddBuildingState();
  }
}

class AddBuildingState extends State<AddTaskListPage> {
  final _formKey = GlobalKey<FormState>();
  final _buildingController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  TaskFrequency? selectedFrequency;
  late List<Task> allTasks;
  List<Task> selectedTasks = [];
  String searchQuery = "";

  List<Task> get _unselectedTasks => allTasks
      .where((t) => !selectedTasks.contains(t))
      .where(
        (t) => t.description.toLowerCase().contains(searchQuery.toLowerCase()),
      )
      .toList();

  @override
  void initState() {
    super.initState();
    allTasks = widget._model.getTasks();
  }

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Add New Task List",
      child: Center(
        child: constrainToPhoneWidth(
          Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                constrainTextBoxWidth(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      mediumTitleText(context, "Task List Name"),
                      TextFormField(
                        controller: _buildingController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a task list name';
                          }
                          if (widget._model.taskListExists(value)) {
                            return 'There is already a building with that name';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                padding8,
                _buildDropdownForTaskListFrequency(),
                padding8,
                Align(
                  alignment: AlignmentGeometry.centerLeft,
                child: mediumTitleText(context, "Tasks in List"),
                ),
                padding8,
                Expanded(flex: 2, child: _buildCurrentListOfTasks()),
                Expanded(flex: 2, child: _buildListOfUnselectedTasks()),
                padding8,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilledButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.pop(context),
                    ),
                    FilledButton(
                      child: Text("Add Task List"),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await widget._model.addTaskList(
                            _buildingController.text,
                            selectedFrequency!,
                            {
                              for (int i = 0; i < selectedTasks.length; i++)
                                selectedTasks[i].tid: i,
                            },
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                    ),
                  ],
                ),
                padding8,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownForTaskListFrequency() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mediumTitleText(context, "Task Frequency"),
        padding8,
        constrainTextBoxWidth(
          DropdownButtonFormField<String>(
            items: TaskFrequency.values
                .map(
                  (f) => DropdownMenuItem(
                    value: f.toDbString,
                    child: Text(f.toDbString),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedFrequency = value?.toTaskFrequency;
              });
            },
            validator: (v) {
              if (v == null) {
                return "Please select a frequency for the task list";
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentListOfTasks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ReorderableListView(
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final task = selectedTasks.removeAt(oldIndex);
                selectedTasks.insert(newIndex, task);
              });
            },
            children: selectedTasks
                .map(
                  (task) => ListTile(
                    key: ValueKey("${task.tid}"),
                    leading: const Icon(Icons.drag_handle),
                    title: Text(task.description),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () =>
                          setState(() => selectedTasks.remove(task)),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildListOfUnselectedTasks() {
    return Column(
      children: [
        Align(
          alignment: AlignmentGeometry.centerStart,
          child: constrainTextBoxWidth(
            TextFormField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search tasks",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => searchQuery = v),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _unselectedTasks.length,
            itemBuilder: (context, index) {
              final task = _unselectedTasks[index];
              return ListTile(
                title: Text(task.description),
                trailing: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.green,
                ),
                onTap: () {
                  setState(() {
                    selectedTasks.add(task);
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
