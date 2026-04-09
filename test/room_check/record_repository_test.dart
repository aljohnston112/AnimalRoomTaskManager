import 'package:animal_room_task_manager/room_check/record_repository.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:animal_room_task_manager/user_management/user_repository.dart';
import 'package:test/test.dart';

void main() {
  var task = Task(description: "A");
  var date = DateTime.fromMicrosecondsSinceEpoch(3);
  var me = User(email: "me@me.com", group: UserGroup.admin);
  var taskRecord = TaskRecord(
    roomName: "1",
    task: task,
    comment: "B",
    dateTime: date,
    doneBy: me
  );
  test("Repository only has added record", () {
    RecordRepository recordRepository = RecordRepository();
    recordRepository.addRecord(taskRecord);
    expect(
      recordRepository.getRecordsForRoom('1', date.toRoomCheckDate()).length,
      1,
    );
    expect(
      recordRepository.getRecordsForRoom('1', date.toRoomCheckDate())[task],
      taskRecord,
    );
  });

  test("Repository only has one instance after same record added twice", () {
    RecordRepository recordRepository = RecordRepository();
    recordRepository.addRecord(taskRecord);
    recordRepository.addRecord(taskRecord);
    expect(
      recordRepository.getRecordsForRoom('1', date.toRoomCheckDate()).length,
      1,
    );
    expect(
      recordRepository.getRecordsForRoom('1', date.toRoomCheckDate())[task],
      taskRecord,
    );
  });
}
