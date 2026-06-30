import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../theme_data.dart';
import 'lab_management_model.dart';
import 'lab_repository.dart';

class LabEditorScreen extends StatefulWidget {
  final LabManagementModel _model;
  final Lab? _lab;

  const LabEditorScreen({
    super.key,
    required LabManagementModel model,
    Lab? lab,
  }) : _lab = lab,
       _model = model;

  @override
  State<StatefulWidget> createState() {
    return LabEditorState();
  }
}

class LabEditorState extends State<LabEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labController = TextEditingController();
  Color pickerColor = Colors.black;
  Color? currentColor = Colors.black;

  @override
  void initState() {
    final lab = widget._lab;
    if (lab != null) {
      currentColor = lab.color;
      _labController.text = lab.name;
    }
    super.initState();
  }

  void changeColor(Color color) {
    setState(() => pickerColor = color);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget._lab == null;
    return buildScaffold(
      title: "Lab Editor",
      context: context,
      child: Form(
        key: _formKey,
        child: Align(
          alignment: Alignment.topCenter,
          child: constrainToPhoneWidth(
            Column(
              children: [
                _buildLabNameEntry(context, isNew),
                padding8,
                _buildColorPickerButton(),
                padding8,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    buildCancelButton(),
                    _buildAddLabButton(context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Align _buildLabNameEntry(BuildContext context, bool isNew) {
    return Align(
      alignment: .topCenter,
      child: constrainTextBoxWidth(
        Column(
          crossAxisAlignment: .start,
          children: [
            mediumTitleText(context, "Lab Name"),
            buildTextFormField(
              enabled: isNew,
              context: context,
              autoFocus: true,
              icon: Icon(Icons.hub, color: Theme.of(context).primaryColor),
              controller: _labController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a lab name';
                }
                if (widget._model.labExists(value) && isNew) {
                  return 'There is already a lab with that name';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Center _buildColorPickerButton() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () {
          openColorPicker();
        },
        icon: CircleAvatar(backgroundColor: currentColor, radius: 12),
        label: Text('Pick Lab Color'),
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
                unNavigate();
              },
            ),
          ],
        );
      },
    );
  }

  FilledButton _buildAddLabButton(BuildContext context) {
    return FilledButton(
      child: Text("Add Lab"),
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
            await widget._model.addLab(
              _labController.text,
              currentColor!,
            );
            if (context.mounted) {
              unNavigate();
            }
        }
      },
    );
  }
}
