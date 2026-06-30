import 'package:animal_room_task_manager/theme_data.dart';
import 'package:flutter/material.dart';

import 'lab_editor_screen.dart';
import 'lab_management_model.dart';
import 'lab_repository.dart';

class LabManagementScreen extends StatelessWidget {
  final LabManagementModel _model;

  const LabManagementScreen({super.key, required model}) : _model = model;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Lab Editor",
      context: context,
      makeScrollable: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: constrainToPhoneWidth(
          Column(
            children: [
              _buildLabList(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [buildGoBackButton(), _buildAddNewLabButton()],
              ),
              padding8,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabList() {
    return Flexible(
      fit: FlexFit.loose,
      child: ListenableBuilder(
        listenable: _model,
        builder: (context, _) {
          return buildScrollable(
            wrapList(
              context,
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    buildSectionHeader(context, "Labs"),
                    padding8,
                    for (var lab in _model.labs) ...[
                      buildCard(
                        context,
                        ListTile(
                          title: mediumTitleText(context, lab.name),
                          trailing: Row(
                            mainAxisAlignment: .end,
                            mainAxisSize: .min,
                            children: [
                              _buildEditIconButton(context, lab),
                              _buildDeleteIconButton(context, lab),
                            ],
                          ),
                          leading: Icon(Icons.circle, color: lab.color),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconButton _buildEditIconButton(BuildContext context, Lab lab) {
    return IconButton(
      icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
      onPressed: () async {
        await navigate(LabEditorScreen(model: _model, lab: lab));
      },
    );
  }

  IconButton _buildDeleteIconButton(BuildContext context, Lab lab) {
    return IconButton(
      icon: Icon(Icons.delete, color: Theme.of(context).primaryColor),
      onPressed: () async {
        _model.deleteLab(lab);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text('Lab deleted'),
            action: SnackBarAction(
              label: 'Undo deletion',
              onPressed: () {
                _model.undeleteLab(lab.name, lab.color);
              },
            ),
          ),
        );
      },
    );
  }

  FilledButton _buildAddNewLabButton() {
    return FilledButton(
      onPressed: () async {
        await navigate(LabEditorScreen(model: _model));
      },
      child: Text("Add New Lab"),
    );
  }
}
