import 'dart:collection';

import 'package:animal_room_task_manager/login_screen/login_use_case.dart';
import 'package:animal_room_task_manager/room_check/record_repository.dart';
import 'package:animal_room_task_manager/room_check/room_check_model.dart';
import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:animal_room_task_manager/user_management/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testTaskEntry();
  testRoomCheckModel();
}

void testRoomCheckModel() {
  final taskA = Task(description: "A");
  final taskB = QuantitativeTask(
    description: "B",
    range: QuantitativeRange(min: 10, max: 100, units: "Bs"),
  );
  final taskC = Task(description: "C");
  final tasks = UnmodifiableListView([taskA, taskB, taskC]);
  final taskList = TaskList(
    name: "D",
    frequency: TaskFrequency.daily,
    tasks: tasks,
  );

  test("RoomCheckModel initializes correctly", () async {
    var database = await Database.create();
    var recordRepository = RecordRepository();
    var userRepository = UserRepository(database: database);
    var loginUseCase = LoginUseCase(userRepository: userRepository);
    var roomCheckModel = RoomCheckModel(
      roomName: "1",
      taskList: taskList,
      recordRepository: recordRepository,
      date: DateTime.now().toRoomCheckDate(),
      loginUseCase: loginUseCase,
    );

    expect(roomCheckModel.taskList, taskList);

    for (var task in tasks) {
      if (task is QuantitativeTask) {
        expect(roomCheckModel.getQuantitativeValueController(task).text, "");
      }
      expect(roomCheckModel.getCommentController(task).text, "");

      expect(roomCheckModel.shouldCommentBeDisplayedForTask(task), false);
      expect(roomCheckModel.isTaskCompleted(task), false);
    }

    var taskEntries = roomCheckModel.getTaskEntries();
    var tasksInEntries = [];
    for (var entry in taskEntries) {
      expect(entry.record, null);
      expect(entry.isCompleted, false);
      tasksInEntries.add(entry.task);
    }
    expect(tasksInEntries, tasks);

    var taskE = Task(description: "E");
    expect(
      () => roomCheckModel.getQuantitativeValueController(taskE),
      throwsA(isA<TypeError>()),
    );
    expect(
      () => roomCheckModel.getCommentController(taskE),
      throwsA(isA<TypeError>()),
    );
  });

  test("Toggling task completion updates task completion status", () async {
    var database = await Database.create();
    var recordRepository = RecordRepository();
    var userRepository = UserRepository(database: database);
    var loginUseCase = LoginUseCase(userRepository: userRepository);
    var roomCheckModel = RoomCheckModel(
      roomName: "1",
      taskList: taskList,
      recordRepository: recordRepository,
      date: DateTime.now().toRoomCheckDate(),
      loginUseCase: loginUseCase,
    );
    expect(roomCheckModel.isTaskCompleted(taskB), false);
    roomCheckModel.toggleTaskCompletion(taskB, true);
    expect(roomCheckModel.isTaskCompleted(taskB), true);
    roomCheckModel.toggleTaskCompletion(taskB, false);
    expect(roomCheckModel.isTaskCompleted(taskB), false);
  });

  test("Adding comment field gives task a comment", () async {
    var database = await Database.create();
    var recordRepository = RecordRepository();
    var userRepository = UserRepository(database: database);
    var loginUseCase = LoginUseCase(userRepository: userRepository);
    var roomCheckModel = RoomCheckModel(
      roomName: "1",
      taskList: taskList,
      recordRepository: recordRepository,
      date: DateTime.now().toRoomCheckDate(),
      loginUseCase: loginUseCase,
    );
    expect(roomCheckModel.shouldCommentBeDisplayedForTask(taskB), false);
    roomCheckModel.onAddCommentClicked(taskB);
    expect(roomCheckModel.shouldCommentBeDisplayedForTask(taskB), true);
    expect(roomCheckModel.getCommentController(taskB).text, "");
  });

  test("Submitting Task adds it to record repository", () async {
    var database = await Database.create();
    var recordRepository = RecordRepository();
    var userRepository = UserRepository(database: database);
    var loginUseCase = LoginUseCase(userRepository: userRepository);
    var roomCheckDate = DateTime.now().toRoomCheckDate();
    var roomCheckModel = RoomCheckModel(
      roomName: "1",
      taskList: taskList,
      recordRepository: recordRepository,
      date: roomCheckDate,
      loginUseCase: loginUseCase,
    );
    var comment = "I'm a comment";
    roomCheckModel.toggleTaskCompletion(taskC, true);
    roomCheckModel.getCommentController(taskC).text = comment;
    roomCheckModel.submit();
    expect(
      recordRepository.getRecordsForRoom("1", roomCheckDate)[taskC]!.comment,
      comment,
    );
  });
}

void testTaskEntry() {
  var date = DateTime.fromMicrosecondsSinceEpoch(3);
  test("TaskEntry completed when set up with record", () {
    var task = Task(description: "A");
    var record = TaskRecord(
      roomName: "1",
      task: task,
      comment: "B",
      dateTime: date,
      doneBy: User(email: "me@me.io", group: UserGroup.admin)
    );
    TaskEntryModel taskEntry = TaskEntryModel(
      task: task,
      record: record,
      date: date.toRoomCheckDate(),
    );
    expect(taskEntry.isCompleted, true);
  });

  test("TaskEntry not completed when set up without record", () {
    var task = Task(description: "A");
    TaskEntryModel taskEntry = TaskEntryModel(
      task: task,
      record: null,
      date: date.toRoomCheckDate(),
    );
    expect(taskEntry.isCompleted, false);
  });
}
