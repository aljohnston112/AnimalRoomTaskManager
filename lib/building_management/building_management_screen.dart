import 'package:animal_room_task_manager/theme_data.dart';
import 'package:flutter/material.dart';

import 'building_management_model.dart';
import 'building_repository.dart';

class BuildingManagementScreen extends StatelessWidget {
  final BuildingManagementModel _model;

  const BuildingManagementScreen({super.key, model}) : _model = model;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Building Editor",
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ListenableBuilder(
            listenable: _model,
            builder: (context, _) {
              return Center(
                child: constrainToPhoneWidth(
                  ListView(
                    shrinkWrap: true,
                    children: [
                      Divider(),
                      for (var building in _model.getBuildings()) ...[
                        ListTile(
                          title: mediumTitleText(context, building.name),
                          trailing: _buildDeleteIconButton(context, building),
                        ),
                        const Divider(),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          padding8,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                  await navigate(AddBuildingPage(model: _model));
                },
                child: Text("Add New Building"),
              ),
            ],
          ),
          padding8,
        ],
      ),
    );
  }

  IconButton _buildDeleteIconButton(BuildContext context, Building building) {
    return IconButton(
      icon: Icon(Icons.delete),
      onPressed: () async {
        _model.deleteBuilding(building);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text('Building deleted'),
            action: SnackBarAction(
              label: 'Undo deletion',
              onPressed: () {
                _model.undeleteBuilding(building.name);
              },
            ),
          ),
        );
      },
    );
  }
}

class AddBuildingPage extends StatefulWidget {
  final BuildingManagementModel _model;

  const AddBuildingPage({super.key, required BuildingManagementModel model})
    : _model = model;

  @override
  State<StatefulWidget> createState() {
    return AddBuildingState();
  }
}

class AddBuildingState extends State<AddBuildingPage> {
  final _formKey = GlobalKey<FormState>();
  final _buildingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Add New Building",
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            constrainTextBoxWidth(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  mediumTitleText(context, "Building Name"),
                  TextFormField(
                    controller: _buildingController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a building';
                      }
                      if (widget._model.buildingExists(value)) {
                        return 'There is already a building with that name';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilledButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                FilledButton(
                  child: Text("Add Building"),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await widget._model.addBuilding(_buildingController.text);
                      if (context.mounted) {
                        Navigator.pop(context);
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
}
