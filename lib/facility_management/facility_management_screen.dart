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
            children: [
              _buildFacilityList(),
              padding8,
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [buildGoBackButton(), _buildAddFacilityButton()],
              ),
              padding8,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFacilityList() {
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
                    buildSectionHeader(context, "Facilities"),
                    padding8,
                    for (var facility in _model.facilities) ...[
                      buildCard(
                        context,
                        ListTile(
                          title: mediumTitleText(context, facility.name),
                          trailing: _buildDeleteIconButton(context, facility),
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

  FilledButton _buildAddFacilityButton() {
    return FilledButton(
      onPressed: () async {
        await navigate(AddFacilityScreen(model: _model));
      },
      child: Text("Add New Facility"),
    );
  }
}
