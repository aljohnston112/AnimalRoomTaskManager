import 'package:animal_room_task_manager/room_check/record_repository.dart';
import 'package:animal_room_task_manager/scheduler/scheduling_model.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:animal_room_task_manager/user_management/user_repository.dart';
import 'package:test/test.dart';

void main() {
  var task = Task(
    tid: 0,
    description: "A",
    managerOnly: false,
    frequency: TaskFrequency.daily,
  );
  var date = DateTime.fromMicrosecondsSinceEpoch(3);
  var me = User(email: "me@me.com", group: UserGroup.admin, uid: null);
  var room = Room(rid: 1, name: "1");
  var taskRecord = TaskRecord(
    room: room,
    task: task,
    dateTime: date,
    doneBy: me,
  );
  test("Repository only has added record", () {
    RecordRepository recordRepository = RecordRepository();
    recordRepository.addRecord(taskRecord);
    expect(
      recordRepository
          .getRecordsForRoom(room, date.toRoomCheckDate(), TaskFrequency.daily)
          .length,
      1,
    );
    expect(
      recordRepository.getRecordsForRoom(
        room,
        date.toRoomCheckDate(),
        TaskFrequency.daily,
      )[task],
      taskRecord,
    );
  });

  test("Repository only has one instance after same record added twice", () {
    RecordRepository recordRepository = RecordRepository();
    recordRepository.addRecord(taskRecord);
    recordRepository.addRecord(taskRecord);
    expect(
      recordRepository
          .getRecordsForRoom(room, date.toRoomCheckDate(), TaskFrequency.daily)
          .length,
      1,
    );
    expect(
      recordRepository.getRecordsForRoom(
        room,
        date.toRoomCheckDate(),
        TaskFrequency.daily,
      )[task],
      taskRecord,
    );
  });
}
