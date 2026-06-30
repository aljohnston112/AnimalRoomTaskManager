import 'package:animal_room_task_manager/room_management/room_editor_screen.dart';
import 'package:animal_room_task_manager/room_management/room_management_model.dart';
import 'package:animal_room_task_manager/room_management/room_repository.dart';
import 'package:flutter/material.dart';

import '../theme_data.dart';

class RoomManagementScreen extends StatelessWidget {
  final RoomManagementModel _model;

  const RoomManagementScreen({super.key, model}) : _model = model;

  @override
  Widget build(BuildContext context) {
    return buildScaffold(
      title: "Room Editor",
      makeScrollable: false,
      context: context,
      child: Align(
        alignment: Alignment.topCenter,
        child: constrainToPhoneWidth(
          Column(
            children: [
              _buildRoomList(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [buildGoBackButton(), buildAddRoomButton()],
              ),
              padding8,
            ],
          ),
        ),
      ),
    );
  }

  Flexible _buildRoomList() {
    return Flexible(
      fit: .loose,
      child: ListenableBuilder(
        listenable: _model,
        builder: (context, _) {
          var rooms = _model.rooms.toList();
          rooms.sort(
            (a, b) => compareAlphanumericRooms(a.roomName, b.roomName),
          );
          return buildScrollable(
            wrapList(
              context,
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    for (final room in rooms) ...[
                      buildCard(
                        context,
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
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  int compareAlphanumericRooms(String a, String b) {
    final RegExp numericRegex = RegExp(r'^(\d+)');

    final matchA = numericRegex.firstMatch(a);
    final matchB = numericRegex.firstMatch(b);

    if (matchA != null && matchB != null) {
      int numA = int.parse(matchA.group(1)!);
      int numB = int.parse(matchB.group(1)!);
      if (numA != numB) {
        return numA.compareTo(numB);
      }
    }
    return a.compareTo(b);
  }

  IconButton _buildEditIconButton(BuildContext context, RoomModel roomModel) {
    return IconButton(
      icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
      onPressed: () async {
        await navigate(
          RoomEditorScreen(
            model: _model,
            title: "Edit Room",
            roomModel: roomModel,
          ),
        );
      },
    );
  }

  IconButton _buildDeleteIconButton(BuildContext context, RoomModel room) {
    return IconButton(
      icon: Icon(Icons.delete, color: Theme.of(context).primaryColor),
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

  FilledButton buildAddRoomButton() {
    return FilledButton(
      onPressed: () async {
        await navigate(
          RoomEditorScreen(
            model: _model,
            title: "Add New Room",
            roomModel: null,
          ),
        );
      },
      child: Text("Add New Room"),
    );
  }
}
