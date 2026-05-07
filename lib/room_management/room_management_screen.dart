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
      makeScrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child:
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildEditIconButton(context, room),
                              _buildDeleteIconButton(context, room),
                            ],
                          ),
                        ),
                        const Divider(),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
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
                  await navigate(
                    AddRoomPage(
                      model: _model,
                      title: "Add New Room",
                      roomModel: null,
                    ),
                  );
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

  IconButton _buildEditIconButton(BuildContext context, RoomModel roomModel) {
    return IconButton(
      icon: Icon(Icons.edit),
      onPressed: () async {
        await navigate(
          AddRoomPage(model: _model, title: "Edit Room", roomModel: roomModel),
        );
      },
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
  final String title;
  final RoomModel? _roomModel;

  const AddRoomPage({
    super.key,
    required RoomManagementModel model,
    required this.title,
    required RoomModel? roomModel,
  }) : _roomModel = roomModel,
       _model = model;

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

  late final bool isNew;

  @override
  void initState() {
    super.initState();
    var roomModel = widget._roomModel;
    isNew = roomModel == null;
    if (roomModel != null) {
      _roomController.text = roomModel.roomName;
      _selectedBid = roomModel.bid;
      _selectedFid = roomModel.fid;
      _selectedLid = roomModel.lid;
      _selectedDailyTlid = widget._model.getTaskList(
        roomModel.tlids,
        TaskFrequency.daily,
      );
      _selectedWeeklyTlid = widget._model.getTaskList(
        roomModel.tlids,
        TaskFrequency.weekly,
      );
      _selectedMonthlyTlid = widget._model.getTaskList(
        roomModel.tlids,
        TaskFrequency.monthly,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: widget.title,
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
                    enabled: isNew,
                    controller: _roomController,
                    validator: (value) {
                      if (isNew) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a room';
                        }
                        if (widget._model.roomExists(value)) {
                          return 'There is already a room with that name';
                        }
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
              editable: isNew,
            ),
            _buildDropdown<Facility>(
              label: "Facility",
              listenable: widget._model.facilities,
              currentValue: _selectedFid,
              itemLabel: (f) => f.name,
              itemId: (f) => f.fid,
              onChanged: (val) => setState(() => _selectedFid = val),
              editable: isNew,
            ),
            _buildDropdown<Lab>(
              label: "Lab",
              listenable: widget._model.labs,
              currentValue: _selectedLid,
              itemLabel: (l) => l.name,
              itemId: (l) => l.lid,
              onChanged: (val) => setState(() => _selectedLid = val),
              editable: true,
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
              editable: true,
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
              editable: true,
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
              editable: true,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilledButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                FilledButton(
                  child: Text(widget.title),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final tlids = [
                        _selectedDailyTlid,
                        _selectedWeeklyTlid,
                        _selectedMonthlyTlid,
                      ].whereType<int>().toList();
                      if (isNew) {
                        await widget._model.addRoom(
                          roomName: _roomController.text,
                          bid: _selectedBid!,
                          fid: _selectedFid!,
                          lid: _selectedLid!,
                          tlids: tlids,
                        );
                      } else {
                        final roomModel = widget._roomModel!;
                        await widget._model.updateRoom(
                          rid: roomModel.rid,
                          lid: _selectedLid!,
                          tlids: tlids,
                        );
                      }
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
    required bool editable,
  }) {
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
                onChanged: editable ? onChanged : null,
                validator: (v) {
                  if (v == null) {
                    return "Please select a $label";
                  }
                  return null;
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
