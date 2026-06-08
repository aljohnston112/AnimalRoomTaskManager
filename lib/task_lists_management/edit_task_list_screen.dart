import 'package:animal_room_task_manager/task_lists_management/add_task_screen.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_management_model.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:animal_room_task_manager/task_lists_management/task_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme_data.dart';

class EditTaskListScreen extends StatefulWidget {
  final TaskListManagementModel _model;
  final String title;
  final TaskList? taskList;

  const EditTaskListScreen({
    super.key,
    required TaskListManagementModel model,
    required this.title,
    required this.taskList,
  }) : _model = model;

  @override
  State<StatefulWidget> createState() {
    return EditTaskListScreenState();
  }
}

class EditTaskListScreenState extends State<EditTaskListScreen> {
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
        (t) =>
            t.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
            (t is QuantitativeTask &&
                ("${t.warningRange.toString().toLowerCase()} "
                        "${t.requiredRange.toString().toLowerCase()}")
                    .contains(searchQuery.toLowerCase())),
      )
      .toList();

  @override
  void initState() {
    super.initState();
    allTasks = widget._model.tasks;
    if (widget.taskList case TaskList taskList) {
      _taskListController.text = taskList.name;
      selectedFrequency = taskList.frequency;

      // Tasks from list sorted by their index
      final indices = taskList.tasks.keys.toList();
      indices.sort((a, b) => a.compareTo(b));
      for (final index in indices) {
        selectedTasks.add(taskList.tasks[index]!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      makeScrollable: false,
      context: context,
      title: widget.title,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: constraints.maxHeight),
              child: Center(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and frequency
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTaskListNameField(),
                          _buildDropdownForTaskListFrequency(),
                        ],
                      ),
                      padding32,
                      // Task lists
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
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          cancelButton(),
                          _buildAddNewTaskButton(context),
                          _buildSubmitButton(context),
                        ],
                      ),
                      padding8,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskListNameField() {
    var taskList = widget.taskList;
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

              if ((taskList == null || _taskListChanged(taskList)) &&
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

  bool _taskListChanged(TaskList? taskList) {
    return taskList?.name != _taskListController.text ||
        selectedFrequency != taskList?.frequency;
  }

  Widget _buildDropdownForTaskListFrequency() {
    var dropdownItems = TaskFrequency.values
        .map(
          (f) =>
              DropdownMenuItem(value: f.toDbString, child: Text(f.toDbString)),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        largeTitleText(context, "Task Frequency"),
        padding8,
        constrainTextBoxWidth(
          DropdownButtonFormField<String>(
            initialValue: selectedFrequency?.toDbString,
            items: dropdownItems,
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
                  .map((task) => _buildTaskTile(task))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  ListTile _buildTaskTile(Task task) {
    return ListTile(
      key: ValueKey("${task.tid}"),
      title: _buildTaskTileText(task),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle, color: Colors.red),
        onPressed: () {
          setState(() => selectedTasks.remove(task));
        },
      ),
    );
  }

  Column _buildTaskTileText(Task task) {
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
          child: Text("Warning range: ${task.warningRange}"),
        ),
      ],
      if (task.requiredRange != null) ...[
        Padding(
          padding: EdgeInsets.only(left: 32),
          child: Text("Required range: ${task.requiredRange}"),
        ),
      ],
    ];
    return texts;
  }

  // TODO deletable
  Widget _buildListOfUnselectedTasks() {
    return Expanded(
      child: Column(
        children: [
          Align(
            alignment: AlignmentGeometry.centerStart,
            child: _buildTaskSearchBox(),
          ),
          // The unselected tasks may get updates if new tasks are loaded
          ListenableBuilder(
            listenable: widget._model.tasksListenable,
            builder: (context, _) {
              return Expanded(
                child: ListView.builder(
                  itemCount: _unselectedTasks.length,
                  itemBuilder: (context, index) {
                    final task = _unselectedTasks[index];
                    return ListTile(
                      title: _buildTaskTileText(task),
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
              );
            },
          ),
        ],
      ),
    );
  }

  ConstrainedBox _buildTaskSearchBox() {
    return constrainTextBoxWidth(
      TextFormField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: "Search tasks",
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (v) => setState(() => searchQuery = v),
      ),
    );
  }

  FilledButton _buildAddNewTaskButton(BuildContext context) {
    return FilledButton(
      child: const Text("Add New Task"),
      onPressed: () => navigate(
        AddTaskScreen(taskModel: TaskModel(taskListRepository: context.read())),
      ),
    );
  }

  FilledButton _buildSubmitButton(BuildContext context) {
    return FilledButton(
      child: Text("Submit"),
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          await _updateTaskList();
          if (context.mounted) {
            unNavigate();
          }
        }
      },
    );
  }

  Future<void> _updateTaskList() async {
    var taskList = widget.taskList;
    bool changed = _taskListChanged(taskList);
    var tidToIndex = {
      for (int i = 0; i < selectedTasks.length; i++) selectedTasks[i].tid: i,
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
      await widget._model.reorderTasks(taskList!.tlid, tidToIndex);
    }
  }
}
