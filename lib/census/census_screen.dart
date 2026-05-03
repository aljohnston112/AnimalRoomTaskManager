import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../scheduler/scheduling_model.dart';
import '../theme_data.dart';
import 'census_model.dart';

class CensusEntryScreen extends StatefulWidget {
  final CensusEntryModel _model;
  final bool _isFirstEntry;
  final Census? _census;
  final Room? _room;

  const CensusEntryScreen({
    super.key,
    required CensusEntryModel model,
    required bool isFirstEntry,
    required Census? censusToEdit,
    required Room? room,
  }) : _room = room,
       _census = censusToEdit,
       _isFirstEntry = isFirstEntry,
       _model = model;

  @override
  State<StatefulWidget> createState() {
    return AddCensusEntryScreenState();
  }
}

class AddCensusEntryScreenState extends State<CensusEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _censusController = TextEditingController();
  int? _selectedAid;
  Room? _selectedRoom;

  @override
  void initState() {
    super.initState();
    _censusController.text = widget._census != null
        ? widget._census!.quantity.toString()
        : "";
    _selectedRoom = widget._room;
    _selectedAid = widget._census?.animal.aid;
  }

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                mediumTitleText(context, "Room"),
                constrainTextBoxWidth(
                  ValueListenableBuilder(
                    valueListenable: widget._model.rooms,
                    builder: (context, items, _) {
                      return DropdownButtonFormField<Room>(
                        initialValue: _selectedRoom,
                        items: items
                            .map(
                              (item) => DropdownMenuItem(
                                value: item.toRoom(),
                                child: Text(item.roomName),
                              ),
                            )
                            .toList(),
                        onChanged: widget._isFirstEntry
                            ? (Room? v) {
                                _selectedRoom = v;
                              }
                            : null,
                        validator: (v) {
                          if (v == null) {
                            return "Please select an room";
                          }
                          return null;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                mediumTitleText(context, "Animal"),
                constrainTextBoxWidth(
                  ValueListenableBuilder(
                    valueListenable: widget._model.animals,
                    builder: (context, items, _) {
                      return DropdownButtonFormField(
                        initialValue: widget._census != null
                            ? widget._census!.animal.aid
                            : _selectedAid,
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
            constrainTextBoxWidth(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  mediumTitleText(context, "Quantity"),
                  TextFormField(
                    keyboardType: TextInputType.numberWithOptions(),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                  onPressed: () {
                    unNavigate();
                  },
                ),
                FilledButton(
                  child: Text("Add Census"),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final animal = widget._model.getAnimal(_selectedAid!);
                      final quantity = int.parse(_censusController.text);
                      if (widget._isFirstEntry) {
                        navigate(
                          CensusScreen(
                            censusScreenModel: CensusScreenModel(
                              census: Census(
                                animal: animal,
                                quantity: quantity,
                              ),
                              room: _selectedRoom!,
                              loginUseCase: context.read(),
                              censusRepository: context.read(),
                            ),
                          ),
                        );
                      } else {
                        unNavigate(
                          result: Census(animal: animal, quantity: quantity),
                        );
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
          mediumTitleText(context, "Census For Room: ${_model.room.name}"),
          padding8,
          CensusRecordList(censusScreenModel: _model),
          padding8,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton(
                child: const Text("Cancel"),
                onPressed: () {
                  unNavigatePast("census");
                },
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
            model: CensusEntryModel(
              animalRepository: context.read(),
              roomRepository: context.read(),
            ),
            isFirstEntry: _model.censusEntries.value.isEmpty,
            censusToEdit: null,
            room: _model.room,
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
        unNavigatePast("census");
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
        "Animal: ${census.animal.name}\nQuantity: ${census.quantity}",
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEditIconButton(context, census),
          _buildDeleteIconButton(context, census),
        ],
      ),
    );
  }

  IconButton _buildEditIconButton(BuildContext context, Census census) {
    return IconButton(
      icon: Icon(Icons.edit),
      onPressed: () async {
        final Census? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CensusEntryScreen(
              model: CensusEntryModel(
                animalRepository: context.read(),
                roomRepository: context.read(),
              ),
              isFirstEntry: _model.censusEntries.value.length < 2,
              censusToEdit: census,
              room: _model.room,
            ),
          ),
        );
        if (result != null) {
          _model.replaceCensusEntry(result);
        }
      },
    );
  }

  IconButton _buildDeleteIconButton(BuildContext context, Census census) {
    return IconButton(
      icon: Icon(Icons.delete),
      onPressed: () async {
        _model.removeCensusEntry(census);
      },
    );
  }
}
