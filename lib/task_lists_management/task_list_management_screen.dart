import 'package:animal_room_task_manager/task_lists_management/task_list_management_model.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:flutter/material.dart';

import '../theme_data.dart';

class TaskListManagementScreen extends StatelessWidget {
  final TaskListManagementModel _model;

  const TaskListManagementScreen({super.key, required model}) : _model = model;

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
                  );
                },
              ),
              padding8,
              Row(
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

class AddTaskListPage extends StatefulWidget {
  final TaskListManagementModel _model;
  final String title;
  final TaskList? taskList;

  const AddTaskListPage({
    super.key,
    required TaskListManagementModel model,
    required this.title,
    required this.taskList,
  }) : _model = model;

  @override
  State<StatefulWidget> createState() {
    return AddTaskListState();
  }
}

class AddTaskListState extends State<AddTaskListPage> {
  final _formKey = GlobalKey<FormState>();
  final _taskListController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  TaskFrequency? selectedFrequency;
  late Set<Task> allTasks;
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
    allTasks = widget._model.getAllTasks();
    if (widget.taskList case TaskList taskList) {
      _taskListController.text = taskList.name;
      selectedFrequency = taskList.frequency;
      for (Task task in taskList.tasks) {
        selectedTasks.add(task);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: widget.title,
      child: Center(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsetsGeometry.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTaskListNameField(),
                    _buildDropdownForTaskListFrequency(),
                  ],
                ),
                padding32,
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCurrentListOfTasks(),
                      padding32,
                      _buildListOfUnselectedTasks(),
                    ],
                  ),
                ),
                padding32,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilledButton(
                      child: const Text("Cancel"),
                      onPressed: () => unNavigate(),
                    ),
                    FilledButton(
                      child: Text(widget.title),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          var taskList = widget.taskList;
                          bool changed = _taskListChanged(taskList);
                          if (changed) {
                            var tidToIndex = {
                              for (int i = 0; i < selectedTasks.length; i++)
                                selectedTasks[i].tid: i,
                            };
                            if (changed) {
                              if (taskList == null) {
                                await widget._model.addTaskList(
                                  _taskListController.text,
                                  selectedFrequency!,
                                  tidToIndex,
                                );
                              } else {
                                await widget._model.editTaskList(
                                  taskList.tlid,
                                  _taskListController.text,
                                  selectedFrequency!,
                                  tidToIndex,
                                );
                              }
                            } else {
                              await widget._model.reorderTasks(
                                taskList!.tlid,
                                tidToIndex,
                              );
                            }
                          }
                          if (context.mounted) {
                            unNavigate();
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

  bool _taskListChanged(TaskList? taskList) {
    return taskList?.name != _taskListController.text ||
        selectedFrequency != taskList?.frequency;
  }

  Widget _buildTaskListNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        largeTitleText(context, "Task List Name"),
        constrainTextBoxWidth(
          TextFormField(
            controller: _taskListController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a task list name';
              }
              var taskList = widget.taskList;
              bool changed = _taskListChanged(taskList);
              if ((taskList == null || changed) &&
                  widget._model.taskListExists(value, selectedFrequency!)) {
                return 'There is already a task list with that name';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownForTaskListFrequency() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        largeTitleText(context, "Task Frequency"),
        padding8,
        constrainTextBoxWidth(
          DropdownButtonFormField<String>(
            initialValue: selectedFrequency?.toDbString,
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
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          largeTitleText(context, "Tasks in List"),
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
                      title: _buildTaskTile(task),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          setState(() => selectedTasks.remove(task));
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListOfUnselectedTasks() {
    return Expanded(
      child: Column(
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
                  title: _buildTaskTile(task),
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
      ),
    );
  }

  Column _buildTaskTile(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(task.description),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [if (task is QuantitativeTask) ..._buildRangeTexts(task)],
        ),
      ],
    );
  }

  List<Widget> _buildRangeTexts(QuantitativeTask task) {
    List<Widget> texts = [
      if (task.warningRange != null) ...[
        Padding(
          padding: EdgeInsets.only(left: 32),
          child: Text(
            "Warning range: "
            "${task.warningRange!.min} to "
            "${task.warningRange!.max} "
            "${task.warningRange!.units}",
          ),
        ),
      ],
      if (task.requiredRange != null) ...[
        Padding(
          padding: EdgeInsets.only(left: 32),
          child: Text(
            "Required range: "
            "${task.requiredRange!.min} to "
            "${task.requiredRange!.max} "
            "${task.requiredRange!.units}",
          ),
        ),
      ],
    ];
    return texts;
  }
}
