import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_data.dart';
import 'census_model.dart';

class CensusEntryScreen extends StatefulWidget {
  final CensusEntryModel _model;

  const CensusEntryScreen({super.key, required CensusEntryModel model})
    : _model = model;

  @override
  State<StatefulWidget> createState() {
    return AddCensusEntryScreenState();
  }
}

class AddCensusEntryScreenState extends State<CensusEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _censusController = TextEditingController();
  int? _selectedAid;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Add Census Entry",
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
                  mediumTitleText(context, "Animal"),
                  constrainTextBoxWidth(
                    ValueListenableBuilder(
                      valueListenable: widget._model.animals,
                      builder: (context, items, _) {
                        return DropdownButtonFormField(
                          initialValue: _selectedAid,
                          items: items
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.aid,
                                  child: Text(item.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => _selectedAid = v,
                          validator: (v) {
                            if (v == null) {
                              return "Please select an animal";
                            }
                            return null;
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            constrainTextBoxWidth(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  mediumTitleText(context, "Quantity"),
                  TextFormField(
                    keyboardType: TextInputType.numberWithOptions(),
                    controller: _censusController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the number of animals';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilledButton(
                  child: const Text("Cancel"),
                  onPressed: () => unNavigate(),
                ),
                FilledButton(
                  child: Text("Add Census"),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      navigate(
                        CensusScreen(
                          censusScreenModel: CensusScreenModel(
                            census: Census(
                              animal: widget._model.getAnimal(_selectedAid!),
                              quantity: int.parse(_censusController.text),
                            ),
                          ),
                        ),
                      );
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

class CensusScreen extends StatelessWidget {
  final CensusScreenModel _model;

  const CensusScreen({super.key, required CensusScreenModel censusScreenModel})
    : _model = censusScreenModel;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Census",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          padding8,
          CensusRecordList(censusScreenModel: _model),
          padding8,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton(
                child: const Text("Cancel"),
                onPressed: () => unNavigate(),
              ),
              _buildAddCensusEntryButton(context),
              _buildCensusRecordButton(context),
            ],
          ),
          padding8,
        ],
      ),
    );
  }

  Widget _buildAddCensusEntryButton(BuildContext context) {
    return FilledButton(
      onPressed: () async {
        final Census? result = await navigate(
          CensusEntryScreen(
            model: CensusEntryModel(animalRepository: context.read()),
          ),
        );
        if (result != null) {
          _model.addCensusEntry(
            Census(animal: result.animal, quantity: result.quantity),
          );
        }
      },
      child: Text("Add Census Entry"),
    );
  }

  Widget _buildCensusRecordButton(BuildContext context) {
    return FilledButton(
      child: const Text("Submit Census"),
      onPressed: () {
        _model.submitCensus();
        unNavigate();
      },
    );
  }
}

class CensusRecordList extends StatelessWidget {
  final CensusScreenModel _model;

  const CensusRecordList({
    super.key,
    required CensusScreenModel censusScreenModel,
  }) : _model = censusScreenModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _model.censusEntries,
      builder: (context, _) {
        return ListView(
          shrinkWrap: true,
          children: _model.censusEntries.value
              .map((entry) => _censusEntryUserListTile(context, entry))
              .toList(),
        );
      },
    );
  }

  ListTile _censusEntryUserListTile(BuildContext context, Census census) {
    return ListTile(
      title: mediumTitleText(
        context,
        "Animal: ${census.animal}\nQuantity: ${census.quantity}",
      ),
      // trailing: Row(
      //   mainAxisSize: MainAxisSize.min,
      //   children: [
      //     _buildEditIconButton(context, census),
      //     _buildDeleteIconButton(context, census),
      //   ],
      // ),
    );
  }

  // IconButton _buildEditIconButton(BuildContext context, User user) {
  //   return IconButton(
  //     icon: Icon(Icons.edit),
  //     onPressed: () async {
  //       final AddUserResult? result = await Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (_) => AddNewUserPage("Edit User", user.email, user.group),
  //         ),
  //       );
  //       if (result != null) {
  //         _model.updateUser(
  //           User(email: result.email, group: result.group, uid: user.uid),
  //         );
  //       }
  //     },
  //   );
  // }
  //
  // IconButton _buildDeleteIconButton(BuildContext context, User user) {
  //   return IconButton(
  //     icon: Icon(Icons.delete),
  //     onPressed: () async {
  //       await showDialog<bool>(
  //         context: context,
  //         builder: (context) =>
  //             _buildDeleteUserConfirmationDialog(user, context),
  //       ).then((result) {
  //         if (result == true) {
  //           _model.removeUser(user);
  //         }
  //       });
  //     },
  //   );
  // }
}
