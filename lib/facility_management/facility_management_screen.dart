import 'package:animal_room_task_manager/theme_data.dart';
import 'package:flutter/material.dart';

import 'add_facility_screen.dart';
import 'facility_management_model.dart';
import 'facility_repository.dart';

class FacilityManagementScreen extends StatelessWidget {
  final FacilityManagementModel _model;

  const FacilityManagementScreen({super.key, required model}) : _model = model;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Facility Editor",
      context: context,
      makeScrollable: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: constrainToPhoneWidth(
          Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListenableBuilder(
                listenable: _model,
                builder: (context, _) {
                  return buildScrollable(
                    wrapList(
                      context,
                      Align(
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            buildSectionHeader(context, "Facilities"),
                            padding8,
                            for (var facility in _model.getFacilities()) ...[
                              Card(
                                elevation: appCardElevation,
                                shadowColor: Theme.of(context).primaryColor,
                                child: ListTile(
                                  title: mediumTitleText(
                                    context,
                                    facility.name,
                                  ),
                                  trailing: _buildDeleteIconButton(
                                    context,
                                    facility,
                                  ),
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
                      await navigate(AddFacilityScreen(model: _model));
                    },
                    child: Text("Add New Facility"),
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

  IconButton _buildDeleteIconButton(BuildContext context, Facility facility) {
    return IconButton(
      icon: Icon(Icons.delete, color: Theme.of(context).primaryColor),
      onPressed: () async {
        _model.deleteFacility(facility);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text('Facility deleted'),
            action: SnackBarAction(
              label: 'Undo deletion',
              onPressed: () {
                _model.undeleteFacility(facility.name);
              },
            ),
          ),
        );
      },
    );
  }
}
