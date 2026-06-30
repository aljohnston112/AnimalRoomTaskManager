import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:animal_room_task_manager/task_lists_management/task_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme_data.dart';

/// A screen where the admin can add new tasks to the system
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
      context: context,
      child: Form(
        key: _formKey,
        child: ListenableBuilder(
          listenable: _model,
          builder: (context, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTaskDescriptionField(context),
                _buildIsAdminOnlyCheckbox(context),
                _buildIsQuantititaveCheckbox(context),
                if (_model.isQuantitative) ...{..._buildRangeFields(context)},
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [buildCancelButton(), _buildAddTaskButton(context)],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Column _buildTaskDescriptionField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mediumTitleText(context, "Task Description"),
        constrainTextBoxWidth(
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
        ),
      ],
    );
  }

  Row _buildIsAdminOnlyCheckbox(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: _model.isManagerOnly,
          onChanged: (val) {
            if (val != null) {
              _model.toggleManagerOnly(val);
            }
          },
        ),
        smallTitleText(context, "Only the admin can complete this task"),
      ],
    );
  }

  Row _buildIsQuantititaveCheckbox(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: _model.isQuantitative,
          onChanged: (val) {
            if (val != null) {
              _model.toggleQuantitative(val);
            }
          },
        ),
        smallTitleText(context, "Requires recording a variable"),
      ],
    );
  }

  List<Widget> _buildRangeFields(BuildContext context) {
    return [
      _buildUnitField(context),
      _buildNeedsWarningRangeCheckbox(context),
      if (_model.needsWarningRange) ...[
        _buildRangeMinField(
          context,
          _maxWarningController,
          _minWarningController,
        ),
        _buildRangeMaxField(
          context,
          _maxWarningController,
          _minWarningController,
        ),
      ],
      _buildNeedsRequiredRangeCheckbox(context),
      if (_model.needsRequiredRange) ...[
        _buildRangeMinField(
          context,
          _maxRequiredController,
          _minRequiredController,
        ),
        _buildRangeMaxField(
          context,
          _maxRequiredController,
          _minRequiredController,
        ),
      ],
    ];
  }

  Column _buildUnitField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mediumTitleText(context, "Unit"),
        constrainTextBoxWidth(
          TextFormField(
            controller: _unitController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a unit';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Row _buildNeedsWarningRangeCheckbox(BuildContext context) {
    return Row(
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
    );
  }

  Column _buildRangeMinField(
    BuildContext context,
    TextEditingController maxController,
    TextEditingController minController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mediumTitleText(context, "Minimum Value"),
        constrainTextBoxWidth(
          TextFormField(
            keyboardType: TextInputType.numberWithOptions(signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            controller: minController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a minimum value';
              }
              if (double.parse(minController.text) >
                  double.parse(maxController.text)) {
                return 'The minimum value must be less than maximum';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Column _buildRangeMaxField(
    BuildContext context,
    TextEditingController maxController,
    TextEditingController minController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mediumTitleText(context, "Maximum Value"),
        constrainTextBoxWidth(
          TextFormField(
            keyboardType: TextInputType.numberWithOptions(signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            controller: maxController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a maximum value';
              }
              if (double.parse(minController.text) >
                  double.parse(maxController.text)) {
                return 'The maximum value must be greater than minimum';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Row _buildNeedsRequiredRangeCheckbox(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: _model.needsRequiredRange,
          onChanged: (val) {
            if (val != null) {
              _model.toggleNeedsRequiredRange(val);
            }
          },
        ),
        smallTitleText(context, "Value recorded must be in range"),
      ],
    );
  }

  Center _buildAddTaskButton(BuildContext context) {
    return Center(
      child: FilledButton(
        child: Text("Add Task"),
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            await _addTask();
            if (context.mounted) {
              _model.refreshTasks();
              unNavigate();
            }
          }
        },
      ),
    );
  }

  Future<void> _addTask() async {
    String description = _descriptionController.text;
    bool isManagerOnly = _model.isManagerOnly;
    if (_model.isQuantitative) {
      late final QuantitativeRange<double>? warningRange;
      if (_minWarningController.text.isNotEmpty &&
          _maxWarningController.text.isNotEmpty) {
        warningRange = QuantitativeRange(
          min: double.parse(_minWarningController.text),
          max: double.parse(_maxWarningController.text),
          units: _unitController.text,
        );
      } else {
        warningRange = null;
      }

      late final QuantitativeRange<double>? requiredRange;
      if (_minRequiredController.text.isNotEmpty &&
          _maxRequiredController.text.isNotEmpty) {
        requiredRange = QuantitativeRange(
          min: double.parse(_minRequiredController.text),
          max: double.parse(_maxRequiredController.text),
          units: _unitController.text,
        );
      } else {
        requiredRange = null;
      }
      await _model.addQuantitativeTask(
        description,
        warningRange,
        requiredRange,
      );
    } else {
      await _model.addTask(description, isManagerOnly);
    }
  }
}
