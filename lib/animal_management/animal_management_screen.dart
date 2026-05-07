import 'package:animal_room_task_manager/theme_data.dart';
import 'package:flutter/material.dart';

import 'animal_management_model.dart';
import 'animal_repository.dart';

class AnimalManagementScreen extends StatelessWidget {
  final AnimalManagementModel _model;

  const AnimalManagementScreen({super.key, model}) : _model = model;

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
                      for (var animal in _model.getAnimals()) ...[
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
                  await navigate(AddAnimalPage(model: _model));
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

  IconButton _buildDeleteIconButton(BuildContext context, Animal animal) {
    return IconButton(
      icon: Icon(Icons.delete),
      onPressed: () async {
        _model.deleteAnimal(animal);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text('Animal deleted'),
            action: SnackBarAction(
              label: 'Undo deletion',
              onPressed: () {
                _model.undeleteAnimal(animal.name);
              },
            ),
          ),
        );
      },
    );
  }
}

class AddAnimalPage extends StatefulWidget {
  final AnimalManagementModel _model;

  const AddAnimalPage({super.key, required AnimalManagementModel model})
    : _model = model;

  @override
  State<StatefulWidget> createState() {
    return AddAnimalState();
  }
}

class AddAnimalState extends State<AddAnimalPage> {
  final _formKey = GlobalKey<FormState>();
  final _animalController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Add New Animal",
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
                    controller: _animalController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a species';
                      }
                      if (widget._model.animalExists(value)) {
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
                      await widget._model.addAnimal(_animalController.text);
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
