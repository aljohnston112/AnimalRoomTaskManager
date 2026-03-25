import 'dart:collection';

import 'package:animal_room_task_manager/room_check/record_repository.dart';
import 'package:animal_room_task_manager/room_check/room_check_model.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
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

  test("RoomCheckModel initializes correctly", () {
    var recordRepository = RecordRepository();
    var roomCheckModel = RoomCheckModel(
      roomName: "1",
      taskList: taskList,
      recordRepository: recordRepository,
    );

    expect(roomCheckModel.taskList, taskList);

    for (var task in tasks) {
      if (task is QuantitativeTask) {
        expect(roomCheckModel.getValueController(task).text, "");
      }
      expect(roomCheckModel.getCommentController(task).text, "");

      expect(roomCheckModel.doesTaskHaveComment(task), false);
      expect(roomCheckModel.isTaskCompleted(task), false);
    }

    var taskRecords = roomCheckModel.taskEntries;
    var tasksInEntries = [];
    for (var entry in taskRecords) {
      expect(entry.record, null);
      expect(entry.isCompleted, false);
      tasksInEntries.add(entry.task);
    }
    expect(tasksInEntries, tasks);

    var taskE = Task(description: "E");
    expect(
      () => roomCheckModel.getValueController(taskE),
      throwsA(isA<TypeError>()),
    );
    expect(
      () => roomCheckModel.getCommentController(taskE),
      throwsA(isA<TypeError>()),
    );
  });

  test("Toggling task completion updates task completion status", () {
    var recordRepository = RecordRepository();
    var roomCheckModel = RoomCheckModel(
      roomName: "1",
      taskList: taskList,
      recordRepository: recordRepository,
    );
    expect(roomCheckModel.isTaskCompleted(taskB), false);
    roomCheckModel.toggleTaskCompletion(taskB, true);
    expect(roomCheckModel.isTaskCompleted(taskB), true);
    roomCheckModel.toggleTaskCompletion(taskB, false);
    expect(roomCheckModel.isTaskCompleted(taskB), false);
  });

  test("Adding comment field gives task a comment", () {
    var recordRepository = RecordRepository();
    var roomCheckModel = RoomCheckModel(
      roomName: "1",
      taskList: taskList,
      recordRepository: recordRepository,
    );
    expect(roomCheckModel.doesTaskHaveComment(taskB), false);
    roomCheckModel.onAddCommentClicked(taskB);
    expect(roomCheckModel.doesTaskHaveComment(taskB), true);
    expect(roomCheckModel.getCommentController(taskB).text, "");
  });

  test("Submitting Task adds it to record repository", () {
    var recordRepository = RecordRepository();
    var roomCheckModel = RoomCheckModel(
      roomName: "1",
      taskList: taskList,
      recordRepository: recordRepository,
    );
    var comment = "I'm a comment";
    roomCheckModel.toggleTaskCompletion(taskC, true);
    roomCheckModel.getCommentController(taskC).text = comment;
    roomCheckModel.submit();
    expect(recordRepository.getRecordsForRoom("1")[taskC]!.comment, comment);
  });
}

void testTaskEntry() {
  test("TaskEntry completed when set up with record", () {
    var task = Task(description: "A");
    var record = TaskRecord(
      roomName: "1",

      task: task,
      comment: "B",
      dateTime: DateTime.fromMicrosecondsSinceEpoch(3),
    );
    TaskEntry taskEntry = TaskEntry(task: task, record: record);
    expect(taskEntry.isCompleted, true);
  });

  test("TaskEntry not completed when set up without record", () {
    var task = Task(description: "A");
    TaskEntry taskEntry = TaskEntry(task: task, record: null);
    expect(taskEntry.isCompleted, false);
  });
}
