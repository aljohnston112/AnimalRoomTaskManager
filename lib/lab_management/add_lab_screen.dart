import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../theme_data.dart';
import 'lab_management_model.dart';

class AddLabScreen extends StatefulWidget {
  final LabManagementModel _model;

  const AddLabScreen({super.key, required LabManagementModel model})
    : _model = model;

  @override
  State<StatefulWidget> createState() {
    return AddLabState();
  }
}

class AddLabState extends State<AddLabScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labController = TextEditingController();
  Color pickerColor = Colors.black;
  Color? currentColor = Colors.black;

  void changeColor(Color color) {
    setState(() => pickerColor = color);
  }

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Add New Lab",
      context: context,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Align(
              alignment: .topCenter,
              child: constrainTextBoxWidth(
                Column(
                  children: [
                    mediumTitleText(context, "Lab Name"),
                    buildTextFormField(
                      context: context,
                      autoFocus: true,
                      icon: Icon(
                        Icons.hub,
                        color: Theme.of(context).primaryColor,
                      ),
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
            ),
            padding8,
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  openColorPicker();
                },
                icon: CircleAvatar(backgroundColor: currentColor, radius: 12),
                label: Text('Pick Lab Color'),
              ),
            ),
            padding4,
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
