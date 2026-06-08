import 'package:animal_room_task_manager/species_management/species_management_model.dart';
import 'package:flutter/material.dart';

import '../theme_data.dart';

class AddSpeciesScreen extends StatefulWidget {
  final SpeciesManagementModel _model;

  const AddSpeciesScreen({super.key, required SpeciesManagementModel model})
      : _model = model;

  @override
  State<StatefulWidget> createState() {
    return AddAnimalState();
  }
}

class AddAnimalState extends State<AddSpeciesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _speciesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Add New Species",
      context: context,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _buildSpeciesField(context)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [cancelButton(), _buildAddSpeciesButton(context)],
            ),
          ],
        ),
      ),
    );
  }

  ConstrainedBox _buildSpeciesField(BuildContext context) {
    return constrainTextBoxWidth(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          mediumTitleText(context, "Species"),
          TextFormField(
            controller: _speciesController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a species';
              }
              if (widget._model.speciesExists(value)) {
                return 'There is already a species with that name';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  FilledButton _buildAddSpeciesButton(BuildContext context) {
    return FilledButton(
      child: Text("Add Species"),
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          await widget._model.addSpecies(_speciesController.text);
          if (context.mounted) {
            unNavigate();
          }
        }
      },
    );
  }
}