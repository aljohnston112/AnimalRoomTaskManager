import 'package:animal_room_task_manager/species_management/add_species_screen.dart';
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
      makeScrollable: false,
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSpeciesList(context),
          padding8,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [buildCancelButton(), _buildAddSpeciesButton()],
          ),
          padding8,
        ],
      ),
    );
  }

  Widget _buildSpeciesList(BuildContext context) {
    return constrainToPhoneWidth(
        ListenableBuilder(
          listenable: _model,
          builder: (context, _) {
            return buildScrollable(
              wrapList(
                context,
                Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      for (var species in _model.species) ...[
                        Card(
                          elevation: appCardElevation,
                          shadowColor: Theme.of(context).primaryColor,
                          child: ListTile(
                            title: mediumTitleText(context, species.name),
                            trailing: _buildDeleteIconButton(context, species),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
      )
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

  FilledButton _buildAddSpeciesButton() {
    return FilledButton(
      onPressed: () async {
        await navigate(AddSpeciesScreen(model: _model));
      },
      child: Text("Add Species"),
    );
  }
}
