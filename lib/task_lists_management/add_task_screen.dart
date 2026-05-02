import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:flutter/material.dart';

import '../theme_data.dart';

class AddTaskScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final TaskModel _model;
  final _minWarningController = TextEditingController();
  final _maxWarningController = TextEditingController();
  final _minRequiredController = TextEditingController();
  final _maxRequiredController = TextEditingController();
  final _unitController = TextEditingController();

  AddTaskScreen({super.key, required TaskModel taskModel}) : _model = taskModel;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Add Task",
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            mediumTitleText(context, "Task Description"),
            TextFormField(
              controller: _descriptionController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a task description';
                }
                if (_model.taskDescriptionExists(value)) {
                  return 'There is already a task with that description';
                }
                return null;
              },
            ),
            ListenableBuilder(
              listenable: _model,
              builder: (context, _) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _model.isManagerOnly,
                          onChanged: (val) {
                            if (val != null) {
                              _model.toggleManagerOnly(val);
                            }
                          },
                        ),
                        smallTitleText(
                          context,
                          "Only the admin can complete this task",
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _model.isQuantitative,
                          onChanged: (val) {
                            if (val != null) {
                              _model.toggleQuantitative(val);
                            }
                          },
                        ),
                        smallTitleText(
                          context,
                          "Requires recording a variable",
                        ),
                      ],
                    ),
                    if (_model._isQuantitative) ...[
                      mediumTitleText(context, "Unit"),
                      TextFormField(
                        controller: _unitController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a unit';
                          }
                          return null;
                        },
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: _model.needsWarningRange,
                            onChanged: (val) {
                              if (val != null) {
                                _model.toggleNeedsWarningRange(val);
                              }
                            },
                          ),
                          smallTitleText(context, "Range for warning"),
                        ],
                      ),
                      if (_model.needsWarningRange) ...[
                        // TODO number only
                        mediumTitleText(context, "Minimum Value"),
                        TextFormField(
                          controller: _minWarningController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a minimum value';
                            }
                            return null;
                          },
                        ),
                        mediumTitleText(context, "Maximum Value"),
                        TextFormField(
                          controller: _maxWarningController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a maximum value';
                            }
                            return null;
                          },
                        ),
                      ],
                      Row(
                        children: [
                          Checkbox(
                            value: _model.needsRequiredRange,
                            onChanged: (val) {
                              if (val != null) {
                                _model.toggleNeedsRequiredRange(val);
                              }
                            },
                          ),
                          smallTitleText(
                            context,
                            "Value recorded must be in range",
                          ),
                        ],
                      ),
                      if (_model._needsRequiredRange) ...[
                        // TODO number only
                        mediumTitleText(context, "Minimum Value"),
                        TextFormField(
                          controller: _minRequiredController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a minimum value';
                            }
                            return null;
                          },
                        ),
                        mediumTitleText(context, "Maximum Value"),
                        TextFormField(
                          controller: _maxRequiredController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a maximum value';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                    FilledButton(
                      child: Text("Add Task"),
                      onPressed: () async {
                        // TODO min < max
                        if (_formKey.currentState!.validate()) {
                          String description = _descriptionController.text;
                          bool isManagerOnly = _model._isManagerOnly;
                          if (_model._isQuantitative) {
                            final warningRange = QuantitativeRange(
                              min: _minWarningController.text as double,
                              max: _minWarningController.text as double,
                              units: _unitController.text,
                              isRequired: false,
                            );
                            final requiredRange = QuantitativeRange(
                              min: _minRequiredController.text as double,
                              max: _maxRequiredController.text as double,
                              units: _unitController.text,
                              isRequired: true,
                            );
                            await _model.addQuantitativeTask(
                              description,
                              warningRange,
                              requiredRange,
                            );
                          } else {
                            await _model.addTask(description, isManagerOnly);
                          }
                          if (context.mounted) {
                            unNavigate();
                          }
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TaskModel extends ChangeNotifier {
  final TaskListRepository _taskListRepository;

  bool _isQuantitative = false;
  bool _isManagerOnly = false;
  bool _needsWarningRange = false;
  bool _needsRequiredRange = false;

  TaskModel({required TaskListRepository taskListRepository})
    : _taskListRepository = taskListRepository {
    _taskListRepository.loadTasks();
  }

  bool? get isQuantitative => _isQuantitative;

  void toggleQuantitative(bool value) {
    _isQuantitative = !_isQuantitative;
    notifyListeners();
  }

  bool? get isManagerOnly => _isManagerOnly;

  void toggleManagerOnly(bool value) {
    _isManagerOnly = !_isManagerOnly;
    notifyListeners();
  }

  bool taskDescriptionExists(String value) {
    return _taskListRepository.taskDescriptionExists(value);
  }

  bool get needsWarningRange => _needsWarningRange;

  void toggleNeedsWarningRange(bool value) {
    _needsWarningRange = !_needsWarningRange;
    notifyListeners();
  }

  bool get needsRequiredRange => _needsRequiredRange;

  void toggleNeedsRequiredRange(bool value) {
    _needsRequiredRange = !_needsRequiredRange;
    notifyListeners();
  }

  Future<void> addQuantitativeTask(
    String description,
    QuantitativeRange<double> warningRange,
    QuantitativeRange<double> requiredRange,
  ) async {
    _taskListRepository.addQuantitativeTask(
      description,
      _isManagerOnly,
      warningRange,
      requiredRange,
    );
  }

  Future<void> addTask(String description, bool isManagerOnly) async {
    _taskListRepository.addTask(description, isManagerOnly);
  }
}
