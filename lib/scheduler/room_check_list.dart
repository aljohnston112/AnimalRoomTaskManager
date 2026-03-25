import 'package:animal_room_task_manager/room_check/record_repository.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:animal_room_task_manager/theme_data.dart';
import 'package:flutter/material.dart';

import '../room_check/room_check_model.dart';
import '../room_check/room_check_screen.dart';

final surgeryRoomDailies = TaskListRepository.dailyTasks[2];
final storageDailies = TaskListRepository.dailyTasks[2];
final cageRoomDailies = TaskListRepository.dailyTasks[3];
final housingRoomDailies = TaskListRepository.dailyTasks[4];
final hibernaculumDailies = TaskListRepository.dailyTasks[5];

final Map<String, TaskList> halseyRoomToFacilityType = {
  "17": storageDailies,
  "19A": housingRoomDailies,
  "19B": housingRoomDailies,
  "19C": housingRoomDailies,
  "19D": hibernaculumDailies,
  "19E/F": cageRoomDailies,
  "19G": surgeryRoomDailies,
  "19H": housingRoomDailies,
  "19J": housingRoomDailies,
  "56A": hibernaculumDailies,
};

final Map<String, TaskList> clowRoomToFacilityType = {
  "36B": housingRoomDailies,
  "36C": housingRoomDailies,
  "36D": housingRoomDailies,
  "36E": housingRoomDailies,
  "36F": housingRoomDailies,
  "36G": storageDailies,
  "36H": housingRoomDailies,
  "36J": surgeryRoomDailies,
  "36K": surgeryRoomDailies,
  "36L": cageRoomDailies,
};

/// A list of rooms
class RoomCheckListScreen extends StatelessWidget {
  final RecordRepository recordRepository;

  const RoomCheckListScreen({super.key, required this.recordRepository});

  @override
  Widget build(BuildContext context) {
    Map<String, TaskList> roomTaskLists = {};
    for (var MapEntry(key: roomName, value: taskList)
        in clowRoomToFacilityType.entries) {
      roomTaskLists["CACF $roomName"] = taskList;
    }
    for (var MapEntry(key: roomName, value: taskList)
        in halseyRoomToFacilityType.entries) {
      roomTaskLists["HACF $roomName"] = taskList;
    }

    return buildScaffold(
      title: "Room Check List",
      child: Center(
        child: Column(
          children: [
            Expanded(
              child: ConstrainedBox(
                // To prevent the list from taking up the full width of a wide screen
                constraints: const BoxConstraints(maxWidth: widePhoneWidth),
                child: _buildRoomList(context, roomTaskLists),
              ),
            ),
            padding8,
            FilledButton(
              child: Text("Delete All Data"),
              onPressed: () {
                recordRepository.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Data Deleted'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            padding8,
          ],
        ),
      ),
    );
  }

  Widget? _buildRoomList(
    BuildContext context,
    Map<String, TaskList> roomTaskLists,
  ) {
    return ListView(
      shrinkWrap: true,
      children: roomTaskLists.entries.map((entry) {
        return _buildRoomCards(
          context,
          entry.key,
          entry.value,
          recordRepository,
        );
      }).toList(),
    );
  }

  Widget _buildRoomCards(
    BuildContext context,
    String roomName,
    TaskList taskList,
    RecordRepository recordRepository,
  ) {
    return Card(
      child: Column(
        children: [
          padding8,
          mediumTitleText(context, roomName),
          padding8,
          buildDailyTaskButton(context, roomName, taskList),
          padding8,
        ],
      ),
    );
  }

  Widget buildDailyTaskButton(
    BuildContext context,
    String roomName,
    TaskList taskList,
  ) {
    return FilledButton(
      child: Text(taskList.name),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoomCheckScreen(
              roomCheckModel: RoomCheckModel(
                roomName: roomName,
                taskList: taskList,
                recordRepository: recordRepository,
              ),
            ),
          ),
        );
      },
    );
  }
}
