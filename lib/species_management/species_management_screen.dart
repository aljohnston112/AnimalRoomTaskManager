import 'package:animal_room_task_manager/theme_data.dart';
import 'package:flutter/material.dart';

import 'species_management_model.dart';
import 'species_repository.dart';

class SpeciesManagementScreen extends StatelessWidget {
  final SpeciesManagementModel _model;

  const SpeciesManagementScreen({super.key, model}) : _model = model;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Species Editor",
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
                      for (var animal in _model.getSpecies()) ...[
                        ListTile(
                          title: mediumTitleText(context, animal.name),
                          trailing: _buildDeleteIconButton(context, animal),
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
                  await navigate(AddSpeciesPage(model: _model));
                },
                child: Text("Add New Species"),
              ),
            ],
          ),
          padding8,
        ],
      ),
    );
  }

  IconButton _buildDeleteIconButton(BuildContext context, Species species) {
    return IconButton(
      icon: Icon(Icons.delete),
      onPressed: () async {
        _model.deleteSpecies(species);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text('Species deleted'),
            action: SnackBarAction(
              label: 'Undo deletion',
              onPressed: () {
                _model.undeleteSpecies(species.name);
              },
            ),
          ),
        );
      },
    );
  }
}

class AddSpeciesPage extends StatefulWidget {
  final SpeciesManagementModel _model;

  const AddSpeciesPage({super.key, required SpeciesManagementModel model})
    : _model = model;

  @override
  State<StatefulWidget> createState() {
    return AddAnimalState();
  }
}

class AddAnimalState extends State<AddSpeciesPage> {
  final _formKey = GlobalKey<FormState>();
  final _speciesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Add New Species",
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
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilledButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                FilledButton(
                  child: Text("Add Animal"),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await widget._model.addSpecies(_speciesController.text);
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
