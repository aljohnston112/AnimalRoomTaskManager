import 'package:animal_room_task_manager/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'lab_management_model.dart';
import 'lab_repository.dart';

class LabManagementScreen extends StatelessWidget {
  final LabManagementModel _model;

  const LabManagementScreen({super.key, model}) : _model = model;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Lab Editor",
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
                        Divider(),
                        for (var lab in _model.getLabs()) ...[
                          ListTile(
                            title: mediumTitleText(context, lab.name),
                            // TODO edit color
                            trailing: _buildDeleteIconButton(context, lab),
                            leading: Icon(Icons.circle, color: lab.color),
                          ),
                          const Divider(),
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
                      builder: (_) => AddLabPage(model: _model),
                    ),
                  );
                },
                child: mediumTitleText(context, "Add New Lab"),
              ),
              padding8,
            ],
          ),
        ),
      ),
    );
  }

  IconButton _buildDeleteIconButton(BuildContext context, Lab lab) {
    return IconButton(
      icon: Icon(Icons.delete),
      onPressed: () async {
        _model.deleteLab(lab);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text('Lab deleted'),
            action: SnackBarAction(
              label: 'Undo deletion',
              onPressed: () {
                _model.undeleteLab(lab.name);
              },
            ),
          ),
        );
      },
    );
  }
}

class AddLabPage extends StatefulWidget {
  final LabManagementModel _model;

  const AddLabPage({super.key, required LabManagementModel model})
    : _model = model;

  @override
  State<StatefulWidget> createState() {
    return AddLabState();
  }
}

class AddLabState extends State<AddLabPage> {
  final _formKey = GlobalKey<FormState>();
  final _labController = TextEditingController();
  Color pickerColor = Colors.white;
  Color? currentColor = Colors.white;

  void changeColor(Color color) {
    setState(() => pickerColor = color);
  }

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Add New Lab",
      child: Center(
        child: constrainToPhoneWidth(
          Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                constrainTextBoxWidth(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      mediumTitleText(context, "Lab Name"),
                      TextFormField(
                        controller: _labController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a lab name';
                          }
                          if (widget._model.labExists(value)) {
                            return 'There is already a lab with that name';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    openColorPicker();
                  },
                  icon: CircleAvatar(backgroundColor: currentColor, radius: 10),
                  label: Text('Pick Lab Color'),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilledButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.pop(context),
                    ),
                    FilledButton(
                      child: Text("Add Lab"),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          bool valid = true;
                          if (currentColor == null) {
                            showSnackBar(context, 'Please choose a color');
                            valid = false;
                          }
                          if (widget._model.existingLabHasColor(currentColor)) {
                            showSnackBar(
                              context,
                              'There is already a lab with that color',
                            );
                            valid = false;
                          }
                          if (valid) {
                            await widget._model.addLab(
                              _labController.text,
                              currentColor!,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void openColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: changeColor,
            ),
            // TODO check these
            // Use Material color picker:
            //
            // child: MaterialPicker(
            //   pickerColor: pickerColor,
            //   onColorChanged: changeColor,
            //   showLabel: true, // only on portrait mode
            // ),
            //
            // Use Block color picker:
            //
            // child: BlockPicker(
            //   pickerColor: currentColor,
            //   onColorChanged: changeColor,
            // ),
            //
            // child: MultipleChoiceBlockPicker(
            //   pickerColors: currentColors,
            //   onColorsChanged: changeColors,
            // ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Choose Color'),
              onPressed: () {
                setState(() => currentColor = pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
