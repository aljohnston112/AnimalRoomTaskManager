import 'dart:collection';

import 'package:animal_room_task_manager/building_management/building_repository.dart';
import 'package:animal_room_task_manager/facility_management/facility_repository.dart';
import 'package:animal_room_task_manager/lab_management/lab_repository.dart';
import 'package:animal_room_task_manager/room_management/room_repository.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:flutter/material.dart';

class RoomManagementModel extends ChangeNotifier {
  final RoomRepository _roomRepository;
  final BuildingRepository _buildingRepository;
  final FacilityRepository _facilityRepository;
  final LabRepository _labRepository;
  final TaskListRepository _taskListRepository;

  ValueNotifier<Set<Building>> get buildings => _buildingRepository.buildings;

  ValueNotifier<Set<Facility>> get facilities => _facilityRepository.facilities;

  ValueNotifier<Set<Lab>> get labs => _labRepository.labs;

  ValueNotifier<UnmodifiableMapView<TaskFrequency, Set<TaskList>>>
  get taskLists => _taskListRepository.taskLists;

  RoomManagementModel({
    required RoomRepository roomRepository,
    required BuildingRepository buildingRepository,
    required FacilityRepository facilityRepository,
    required LabRepository labRepository,
    required TaskListRepository taskListRepository,
  }) : _roomRepository = roomRepository,
       _buildingRepository = buildingRepository,
       _facilityRepository = facilityRepository,
       _labRepository = labRepository,
       _taskListRepository = taskListRepository {
    _roomRepository.rooms.addListener(() {
      notifyListeners();
    });
    // TODO could be a single database call to get all the information
    _buildingRepository.loadBuildings();
    _facilityRepository.loadFacilities();
    _labRepository.loadLabs();
    _taskListRepository.loadTaskLists();
    _roomRepository.loadRooms();
    notifyListeners();
  }

  Set<RoomModel> getRooms() {
    return _roomRepository.rooms.value;
  }

  bool roomExists(String? roomName) {
    return roomName != null &&
        getRooms().map((f) => f.roomName).contains(roomName);
  }

  Future<void> addRoom({
    required String roomName,
    required int lid,
    required int fid,
    required int bid,
    required List<int> tlids,
  }) async {
    await _roomRepository.addRoom(
      roomName: roomName,
      lid: lid,
      fid: fid,
      bid: bid,
      tlids: tlids,
    );
  }

  Future<void> deleteRoom(RoomModel room) async {
    await _roomRepository.deleteRoom(room);
  }

  Future<void> undeleteRoom(String roomName) async {
    await _roomRepository.undeleteRoom(roomName);
  }

  int? getTaskList(List<int> tlids, TaskFrequency frequency) {
    for (final tlid in tlids) {
      final taskList = taskLists.value[frequency]
          ?.where((tl) => tl.tlid == tlid)
          .firstOrNull;
      if (taskList != null) {
        return tlid;
      }
    }
    return null;
  }

  Future<void> updateRoom({
    required int rid,
    required int lid,
    required List<int> tlids,
  }) async {
    await _roomRepository.updateRoom(rid: rid, lid: lid, tlids: tlids);
  }
}
