import 'package:animal_room_task_manager/room_management/room_management_model.dart';
import 'package:animal_room_task_manager/room_management/room_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../building_management/building_repository.dart';
import '../facility_management/facility_repository.dart';
import '../lab_management/lab_repository.dart';
import '../task_lists_management/task_list_repository.dart';
import '../theme_data.dart';

class RoomEditorScreen extends StatefulWidget {
  final RoomManagementModel _model;
  final String title;
  final RoomModel? _roomModel;

  const RoomEditorScreen({
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

class AddRoomState extends State<RoomEditorScreen> {
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
      context: context,
      child: Form(
        key: _formKey,
        child: Align(
          alignment: .topCenter,
          child: constrainToPhoneWidth(
            SingleChildScrollView(
              child: Column(
                children: [
                  constrainTextBoxWidth(_buildRoomNameEntry(context)),
                  padding8,
                  ..._buildDropdowns(),
                  padding8,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildCancelButton(),
                      _buildSubmitButton(context),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Column _buildRoomNameEntry(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mediumTitleText(context, "Room Name"),
        buildTextFormField(
          icon: Icon(Icons.meeting_room, color: Theme.of(context).primaryColor),
          autoFocus: isNew,
          context: context,
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
    );
  }

  List<Widget> _buildDropdowns() {
    return [
      _buildDropdown<Building>(
        label: "Building",
        listenable: widget._model.buildingsListenable,
        currentValue: _selectedBid,
        itemLabel: (b) => b.name,
        itemId: (b) => b.bid,
        onChanged: (val) => setState(() => _selectedBid = val),
        editable: isNew,
        icon: Icon(
          Icons.corporate_fare,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      padding8,
      _buildDropdown<Facility>(
        label: "Facility",
        listenable: widget._model.facilitiesListenable,
        currentValue: _selectedFid,
        itemLabel: (f) => f.name,
        itemId: (f) => f.fid,
        onChanged: (val) => setState(() => _selectedFid = val),
        editable: isNew,
        icon: Icon(Icons.domain_add, color: Theme.of(context).primaryColor),
      ),
      padding8,
      _buildDropdown<Lab>(
        label: "Lab",
        listenable: widget._model.labsListenable,
        currentValue: _selectedLid,
        itemLabel: (l) => l.name,
        itemId: (l) => l.lid,
        onChanged: (val) => setState(() => _selectedLid = val),
        editable: true,
        icon: Icon(Icons.hub, color: Theme.of(context).primaryColor),
        autofocus: !isNew,
      ),
      padding8,
      _buildDropdown<TaskList>(
        label: "Daily Task List",
        listenable: ValueNotifier(
          widget._model.taskListsListenable.value[TaskFrequency.daily] ?? {},
        ),
        currentValue: _selectedDailyTlid,
        itemLabel: (tl) => tl.name,
        itemId: (tl) => tl.tlid,
        onChanged: (val) => setState(() => _selectedDailyTlid = val),
        editable: true,
        icon: Icon(Icons.list_alt, color: Theme.of(context).primaryColor),
      ),
      padding8,
      _buildDropdown<TaskList>(
        label: "Weekly Task List",
        listenable: ValueNotifier(
          widget._model.taskListsListenable.value[TaskFrequency.weekly] ?? {},
        ),
        currentValue: _selectedWeeklyTlid,
        itemLabel: (tl) => tl.name,
        itemId: (tl) => tl.tlid,
        onChanged: (val) => setState(() => _selectedWeeklyTlid = val),
        editable: true,
        icon: Icon(Icons.list_alt, color: Theme.of(context).primaryColor),
      ),
      padding8,
      _buildDropdown<TaskList>(
        label: "Monthly Task List",
        listenable: ValueNotifier(
          widget._model.taskListsListenable.value[TaskFrequency.monthly] ?? {},
        ),
        currentValue: _selectedMonthlyTlid,
        itemLabel: (tl) => tl.name,
        itemId: (tl) => tl.tlid,
        onChanged: (val) => setState(() => _selectedMonthlyTlid = val),
        editable: true,
        icon: Icon(Icons.list_alt, color: Theme.of(context).primaryColor),
      ),
    ];
  }

  Widget _buildDropdown<T>({
    required String label,
    required ValueListenable<Set<T>> listenable,
    required int? currentValue,
    required String Function(T) itemLabel,
    required int Function(T) itemId,
    required void Function(int?) onChanged,
    required bool editable,
    required Icon icon,
    bool autofocus = false,
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
                decoration: InputDecoration(
                  prefixIcon: icon,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  errorMaxLines: 8,
                ),
                initialValue: currentValue,
                isExpanded: true,
                items: items
                    .map(
                      (item) => DropdownMenuItem(
                    value: itemId(item),
                    child: Text(itemLabel(item), overflow: .fade),
                  ),
                )
                    .toList(),
                onChanged: editable ? onChanged : null,
                autofocus: autofocus,
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

  FilledButton _buildSubmitButton(BuildContext context) {
    return FilledButton(
      child: Text("Submit"),
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
            unNavigate();
          }
        }
      },
    );
  }

}
