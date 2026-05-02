import 'package:animal_room_task_manager/facility_management/facility_repository.dart';
import 'package:animal_room_task_manager/room_management/room_management_model.dart';
import 'package:animal_room_task_manager/room_management/room_repository.dart';
import 'package:flutter/material.dart';

import '../building_management/building_repository.dart';
import '../lab_management/lab_repository.dart';
import '../task_lists_management/task_list_repository.dart';
import '../theme_data.dart';

class RoomManagementScreen extends StatelessWidget {
  final RoomManagementModel _model;

  const RoomManagementScreen({super.key, model}) : _model = model;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Room Editor",
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
                      for (var room in _model.getRooms()) ...[
                        ListTile(
                          title: mediumTitleText(context, room.roomName),
                          trailing: _buildDeleteIconButton(context, room),
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
                  await navigate(AddRoomPage(model: _model));
                },
                child: Text("Add New Room"),
              ),
            ],
          ),
          padding8,
        ],
      ),
    );
  }

  IconButton _buildDeleteIconButton(BuildContext context, RoomModel room) {
    return IconButton(
      icon: Icon(Icons.delete),
      onPressed: () async {
        _model.deleteRoom(room);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text('Room deleted'),
            action: SnackBarAction(
              label: 'Undo deletion',
              onPressed: () {
                _model.undeleteRoom(room.roomName);
              },
            ),
          ),
        );
      },
    );
  }
}

class AddRoomPage extends StatefulWidget {
  final RoomManagementModel _model;

  const AddRoomPage({super.key, required RoomManagementModel model})
    : _model = model;

  @override
  State<StatefulWidget> createState() {
    return AddRoomState();
  }
}

class AddRoomState extends State<AddRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _roomController = TextEditingController();

  int? _selectedBid;
  int? _selectedFid;
  int? _selectedLid;
  int? _selectedDailyTlid;
  int? _selectedWeeklyTlid;
  int? _selectedMonthlyTlid;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Add New Room",
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
                  mediumTitleText(context, "Room Name"),
                  TextFormField(
                    controller: _roomController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a room';
                      }
                      if (widget._model.roomExists(value)) {
                        return 'There is already a room with that name';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            _buildDropdown<Building>(
              label: "Building",
              listenable: widget._model.buildings,
              currentValue: _selectedBid,
              itemLabel: (b) => b.name,
              itemId: (b) => b.bid,
              onChanged: (val) => setState(() => _selectedBid = val),
            ),
            _buildDropdown<Facility>(
              label: "Facility",
              listenable: widget._model.facilities,
              currentValue: _selectedFid,
              itemLabel: (f) => f.name,
              itemId: (f) => f.fid,
              onChanged: (val) => setState(() => _selectedFid = val),
            ),
            _buildDropdown<Lab>(
              label: "Lab",
              listenable: widget._model.labs,
              currentValue: _selectedLid,
              itemLabel: (l) => l.name,
              itemId: (l) => l.lid,
              onChanged: (val) => setState(() => _selectedLid = val),
            ),
            _buildDropdown<TaskList>(
              label: "Daily Task List",
              listenable: ValueNotifier(
                widget._model.taskLists.value[TaskFrequency.daily] ?? {},
              ),
              currentValue: _selectedDailyTlid,
              itemLabel: (tl) => tl.name,
              itemId: (tl) => tl.tlid,
              onChanged: (val) => setState(() => _selectedDailyTlid = val),
            ),
            _buildDropdown<TaskList>(
              label: "Weekly Task List",
              listenable: ValueNotifier(
                widget._model.taskLists.value[TaskFrequency.weekly] ?? {},
              ),
              currentValue: _selectedWeeklyTlid,
              itemLabel: (tl) => tl.name,
              itemId: (tl) => tl.tlid,
              onChanged: (val) => setState(() => _selectedWeeklyTlid = val),
            ),
            _buildDropdown<TaskList>(
              label: "Monthly Task List",
              listenable: ValueNotifier(
                widget._model.taskLists.value[TaskFrequency.monthly] ?? {},
              ),
              currentValue: _selectedMonthlyTlid,
              itemLabel: (tl) => tl.name,
              itemId: (tl) => tl.tlid,
              onChanged: (val) => setState(() => _selectedMonthlyTlid = val),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilledButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                FilledButton(
                  child: Text("Add Room"),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final tlids = [
                        _selectedDailyTlid,
                        _selectedWeeklyTlid,
                        _selectedMonthlyTlid,
                      ].whereType<int>().toList();

                      await widget._model.addRoom(
                        roomName: _roomController.text,
                        bid: _selectedBid!,
                        fid: _selectedFid!,
                        lid: _selectedLid!,
                        tlids: tlids,
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
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required ValueNotifier<Set<T>> listenable,
    required int? currentValue,
    required String Function(T) itemLabel,
    required int Function(T) itemId,
    required void Function(int?) onChanged,
  }) {
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mediumTitleText(context, "Monthly Task List"),
        constrainTextBoxWidth(
          DropdownButtonFormField(items: [], onChanged: (value) {}),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mediumTitleText(context, label),
        constrainTextBoxWidth(
          ValueListenableBuilder<Set<T>>(
            valueListenable: listenable,
            builder: (context, items, _) {
              return DropdownButtonFormField(
                initialValue: currentValue,
                items: items
                    .map(
                      (item) => DropdownMenuItem(
                        value: itemId(item),
                        child: Text(itemLabel(item)),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              );
            },
          ),
        ),
      ],
    );
  }
}
