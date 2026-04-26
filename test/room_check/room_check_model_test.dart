import 'dart:collection';

import 'package:animal_room_task_manager/login_screen/login_use_case.dart';
import 'package:animal_room_task_manager/room_check/record_repository.dart';
import 'package:animal_room_task_manager/room_check/room_check_model.dart';
import 'package:animal_room_task_manager/room_check/room_check_repository.dart';
import 'package:animal_room_task_manager/scheduler/scheduling_model.dart';
import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:animal_room_task_manager/user_management/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testTaskEntry();
  testRoomCheckModel();
}

void testRoomCheckModel() {
  final taskA = Task(
    tid: 0,
    description: "A",
    managerOnly: false,
  );
  final taskB = QuantitativeTask(
    tid: 0,
    description: "B",
    ranges: [
      QuantitativeRange(min: 10, max: 100, units: "Bs", isRequired: false),
    ],
    managerOnly: false,
  );
  final taskC = Task(
    tid: 0,
    description: "C",
    managerOnly: false,
  );
  final tasks = UnmodifiableListView([taskA, taskB, taskC]);
  final taskList = TaskList(
    name: "D",
    frequency: TaskFrequency.weekly,
    tasks: tasks,
    tlid: 1,
  );

  // TODO mock database
  // test("RoomCheckModel initializes correctly", () async {
  //   var database = await Database.create();
  //   var recordRepository = RecordRepository();
  //   var roomCheckRepository = RoomCheckRepository(database: database);
  //   var userRepository = UserRepository(database: database);
  //   var loginUseCase = LoginUseCase(userRepository: userRepository);
  //   final room = Room(rid: 1, name: "1");
  //   var roomCheckModel = RoomCheckModel(
  //     buildingName: 'building',
  //     taskList: taskList,
  //     recordRepository: recordRepository,
  //     roomCheckRepository: roomCheckRepository,
  //     date: DateTime.now().toRoomCheckDate(),
  //     loginUseCase: loginUseCase,
  //     room: room,
  //   );
  //
  //   expect(roomCheckModel.taskList, taskList);
  //
  //   for (var task in tasks) {
  //     if (task is QuantitativeTask) {
  //       expect(roomCheckModel.getQuantitativeValueController(task).text, "");
  //     }
  //     expect(roomCheckModel.getCommentController().text, "");
  //
  //     expect(roomCheckModel.shouldCommentBeDisplayed(), false);
  //     expect(roomCheckModel.isTaskCompleted(task), false);
  //   }
  //
  //   var taskEntries = roomCheckModel.getTaskEntries();
  //   var tasksInEntries = [];
  //   for (var entry in taskEntries) {
  //     expect(entry.record, null);
  //     expect(entry.isCompleted, false);
  //     tasksInEntries.add(entry.task);
  //   }
  //   expect(tasksInEntries, tasks);
  //
  //   var taskE = Task(
  //     tid: 0,
  //     description: "E",
  //     managerOnly: false,
  //     frequency: TaskFrequency.weekly,
  //   );
  //   expect(
  //     () => roomCheckModel.getQuantitativeValueController(taskE),
  //     throwsA(isA<TypeError>()),
  //   );
  // });
  //
  // test("Toggling task completion updates task completion status", () async {
  //   var database = await Database.create();
  //   var recordRepository = RecordRepository();
  //   var roomCheckRepository = RoomCheckRepository(database: database);
  //   var userRepository = UserRepository(database: database);
  //   var loginUseCase = LoginUseCase(userRepository: userRepository);
  //   final room = Room(rid: 1, name: "1");
  //   var roomCheckModel = RoomCheckModel(
  //     room: room,
  //     taskList: taskList,
  //     recordRepository: recordRepository,
  //     roomCheckRepository: roomCheckRepository,
  //     date: DateTime.now().toRoomCheckDate(),
  //     loginUseCase: loginUseCase,
  //     buildingName: 'building',
  //   );
  //   expect(roomCheckModel.isTaskCompleted(taskB), false);
  //   roomCheckModel.toggleTaskCompletion(taskB, true);
  //   expect(roomCheckModel.isTaskCompleted(taskB), true);
  //   roomCheckModel.toggleTaskCompletion(taskB, false);
  //   expect(roomCheckModel.isTaskCompleted(taskB), false);
  // });
  //
  // test("Adding comment field gives task a comment", () async {
  //   var database = await Database.create();
  //   var recordRepository = RecordRepository();
  //   var roomCheckRepository = RoomCheckRepository(database: database);
  //   var userRepository = UserRepository(database: database);
  //   var loginUseCase = LoginUseCase(userRepository: userRepository);
  //   final room = Room(rid: 1, name: "1");
  //   var roomCheckModel = RoomCheckModel(
  //     buildingName: 'building',
  //     taskList: taskList,
  //     recordRepository: recordRepository,
  //     roomCheckRepository: roomCheckRepository,
  //     date: DateTime.now().toRoomCheckDate(),
  //     loginUseCase: loginUseCase,
  //     room: room,
  //   );
  //   expect(roomCheckModel.shouldCommentBeDisplayed(), false);
  //   roomCheckModel.onAddCommentClicked();
  //   expect(roomCheckModel.shouldCommentBeDisplayed(), true);
  //   expect(roomCheckModel.getCommentController().text, "");
  // });
  //
  // test("Submitting Task adds it to record repository", () async {
  //   var database = await Database.create();
  //   var recordRepository = RecordRepository();
  //   var roomCheckRepository = RoomCheckRepository(database: database);
  //   var userRepository = UserRepository(database: database);
  //   var loginUseCase = LoginUseCase(userRepository: userRepository);
  //   var roomCheckDate = DateTime.now().toRoomCheckDate();
  //   var roomName = "1";
  //   final room = Room(rid: 1, name: roomName);
  //   var buildingName = 'building';
  //   var roomCheckModel = RoomCheckModel(
  //     buildingName: buildingName,
  //     taskList: taskList,
  //     recordRepository: recordRepository,
  //     roomCheckRepository: roomCheckRepository,
  //     date: roomCheckDate,
  //     loginUseCase: loginUseCase,
  //     room: room,
  //   );
  //   var comment = "I'm a comment";
  //   roomCheckModel.toggleTaskCompletion(taskC, true);
  //   roomCheckModel.getCommentController().text = comment;
  //   roomCheckModel.submit();
  //   expect(
  //     roomCheckRepository
  //         .getRoomCheck(buildingName, roomCheckDate, taskList.frequency, room)!
  //         .comment,
  //     comment,
  //   );
  // });
}

void testTaskEntry() {
  var date = DateTime.fromMicrosecondsSinceEpoch(3);
  test("TaskEntry completed when set up with record", () {
    var task = Task(
      tid: 0,
      description: "A",
      managerOnly: false,
    );
    final room = Room(rid: 1, name: "1");
    var record = TaskRecord(
      room: room,
      task: task,
      dateTime: date,
      doneBy: User(email: "me@me.io", group: UserGroup.admin, uid: null),
      rcid: 0,
    );
    TaskEntryModel taskEntry = TaskEntryModel(
      task: task,
      record: record,
      date: date.toRoomCheckDate(),
    );
    expect(taskEntry.isCompleted, true);
  });

  test("TaskEntry not completed when set up without record", () {
    var task = Task(
      tid: 0,
      description: "A",
      managerOnly: false,
    );
    TaskEntryModel taskEntry = TaskEntryModel(
      task: task,
      record: null,
      date: date.toRoomCheckDate(),
    );
    expect(taskEntry.isCompleted, false);
  });
}
