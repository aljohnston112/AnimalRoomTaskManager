import 'package:animal_room_task_manager/theme_data.dart';
import 'package:flutter/material.dart';

import 'add_lab_screen.dart';
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
              ListenableBuilder(
                listenable: _model,
                builder: (context, _) {
                  return Center(
                    child: buildScrollable(
                      wrapList(
                        context,
                        Align(
                          alignment: Alignment.topCenter,
                          child: Column(
                            children: [
                              buildSectionHeader(context, "Labs"),
                              padding8,
                              for (var lab in _model.getLabs()) ...[
                                Card(
                                  elevation: appCardElevation,
                                  shadowColor: Theme.of(context).primaryColor,
                                  child: ListTile(
                                    title: mediumTitleText(context, lab.name),
                                    // TODO edit color
                                    trailing: _buildDeleteIconButton(
                                      context,
                                      lab,
                                    ),
                                    leading: Icon(
                                      Icons.circle,
                                      color: lab.color,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilledButton(onPressed: unNavigate, child: Text("Go Back")),
                  FilledButton(
                    onPressed: () async {
                      await navigate(AddLabScreen(model: _model));
                    },
                    child: Text("Add New Lab"),
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
                _model.undeleteLab(lab.name);
              },
            ),
          ),
        );
      },
    );
  }
}
