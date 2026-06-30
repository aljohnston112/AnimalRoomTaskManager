import 'package:animal_room_task_manager/theme_data.dart';
import 'package:flutter/material.dart';

import 'add_building_page.dart';
import 'building_management_model.dart';
import 'building_repository.dart';

/// Displays all rooms
/// and let the user add or delete rooms
class BuildingManagementScreen extends StatelessWidget {
  final BuildingManagementModel _model;

  const BuildingManagementScreen({super.key, model}) : _model = model;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Building Editor",
      context: context,
      makeScrollable: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: constrainToPhoneWidth(
          Column(
            children: [
              _buildBuildingList(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [buildGoBackButton(), _buildAddBuildingButton()],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuildingList() {
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
                    buildSectionHeader(context, "Buildings"),
                    padding8,
                    for (var building in _model.buildings) ...[
                      buildCard(
                        context,
                        ListTile(
                          title: mediumTitleText(context, building.name),
                          trailing: _buildDeleteIconButton(context, building),
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

  IconButton _buildDeleteIconButton(BuildContext context, Building building) {
    return IconButton(
      icon: Icon(Icons.delete, color: Theme.of(context).primaryColor),
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

  FilledButton _buildAddBuildingButton() {
    return FilledButton(
      onPressed: () async {
        await navigate(AddBuildingPage(model: _model));
      },
      child: Text("Add New Building"),
    );
  }
}
