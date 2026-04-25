import 'package:animal_room_task_manager/theme_data.dart';
import 'package:flutter/material.dart';

import 'facility_management_model.dart';
import 'facility_repository.dart';

class FacilityManagementScreen extends StatelessWidget {
  final FacilityManagementModel _model;

  const FacilityManagementScreen({super.key, model}) : _model = model;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Facility Editor",
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
                        for (var facility in _model.getFacilities()) ...[
                          ListTile(
                            title: mediumTitleText(context, facility.name),
                            trailing: _buildDeleteIconButton(context, facility),
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
                      builder: (_) => AddFacilityPage(model: _model),
                    ),
                  );
                },
                child: mediumTitleText(context, "Add New Facility"),
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
      icon: Icon(Icons.delete),
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

class AddFacilityPage extends StatefulWidget {
  final FacilityManagementModel _model;

  const AddFacilityPage({super.key, required FacilityManagementModel model})
    : _model = model;

  @override
  State<StatefulWidget> createState() {
    return AddFacilityState();
  }
}

class AddFacilityState extends State<AddFacilityPage> {
  final _formKey = GlobalKey<FormState>();
  final _facilityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Add New Facility Name",
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
                      mediumTitleText(context, "Facility Name"),
                      TextFormField(
                        controller: _facilityController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a facility';
                          }
                          if (widget._model.facilityExists(value)) {
                            return 'There is already a facility with that name';
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
                      child: Text("Add Facility"),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await widget._model.addFacility(
                            _facilityController.text,
                          );
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
        ),
      ),
    );
  }
}
