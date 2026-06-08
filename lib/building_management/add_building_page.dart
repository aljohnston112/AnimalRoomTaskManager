import 'package:flutter/material.dart';

import '../theme_data.dart';
import 'building_management_model.dart';

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
      context: context,
      makeScrollable: false,
      child: Form(
        key: _formKey,
        child: Align(
          alignment: .topCenter,
          child: constrainToPhoneWidth(
            Column(
              children: [
                buildScrollable(
                  constrainTextBoxWidth(
                    wrapList(
                      context,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          mediumTitleText(context, "Building Name"),
                          buildTextFormField(
                            context: context,
                            controller: _buildingController,
                            autoFocus: true,
                            icon: Icon(
                              Icons.corporate_fare,
                              color: Theme.of(context).colorScheme.primary,
                            ),
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
                          await widget._model.addBuilding(
                            _buildingController.text,
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
