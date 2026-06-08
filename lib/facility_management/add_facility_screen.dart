import 'package:flutter/material.dart';

import '../theme_data.dart';
import 'facility_management_model.dart';

class AddFacilityScreen extends StatefulWidget {
  final FacilityManagementModel _model;

  const AddFacilityScreen({super.key, required FacilityManagementModel model})
    : _model = model;

  @override
  State<StatefulWidget> createState() {
    return AddFacilityState();
  }
}

class AddFacilityState extends State<AddFacilityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _facilityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Add New Facility Name",
      context: context,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: .topCenter,
              child: constrainTextBoxWidth(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    mediumTitleText(context, "Facility Name"),
                    buildTextFormField(
                      context: context,
                      autoFocus: true,
                      controller: _facilityController,
                      icon: Icon(
                        Icons.domain_add,
                        color: Theme.of(context).primaryColor,
                      ),
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
            ),
            padding8,
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                      await widget._model.addFacility(_facilityController.text);
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
