import 'dart:collection';

import 'package:flutter/material.dart';

class Task {
  final String description;

  Task({required this.description});
}

class QuantitativeRange<T> {
  final T min;
  final T max;
  final String units;

  QuantitativeRange({
    required this.min,
    required this.max,
    required this.units,
  });
}

class QuantitativeTask<T> extends Task {
  final QuantitativeRange<T> range;

  QuantitativeTask({required super.description, required this.range});
}

enum TaskFrequency { daily, weekly, monthly }

extension TaskFrequencyParser on String {
  TaskFrequency get toTaskFrequency {
    switch (this) {
      case 'Daily':
        return TaskFrequency.daily;
      case 'Weekly':
        return TaskFrequency.weekly;
      case 'Monthly':
        return TaskFrequency.monthly;
      default:
        throw ArgumentError('Invalid RoomCheckState string: $this');
    }
  }
}

class TaskList {
  final String name;
  final TaskFrequency frequency;
  final UnmodifiableListView<Task> tasks;

  TaskList({required this.name, required this.frequency, required this.tasks});
}

class TaskListRepository extends ChangeNotifier {
  static final tempTask = QuantitativeTask(
    description: "Room Temperature",
    range: QuantitativeRange(min: 68, max: 79, units: "Fahrenheit"),
  );

  static final hibernaculumTempTask = QuantitativeTask(
    description: "Room Temperature",
    range: QuantitativeRange(min: 32, max: 42, units: "Fahrenheit"),
  );

  static final humidityTask = QuantitativeTask(
    description: "Room Humidity",
    range: QuantitativeRange(min: 30, max: 70, units: "RH"),
  );

  static final hibernaculumHumidityTask = QuantitativeTask(
    description: "Room Humidity",
    range: QuantitativeRange(min: 30, max: 70, units: "RH"),
  );

  static final quantitativeTasks = UnmodifiableListView([
    tempTask,
    humidityTask,
  ]);

  static final wipeCounterAndSweep = Task(description: "Wipe Counters & Sweep");
  static final checkVerminTrap = Task(description: "Check Vermin Trap");

  static final basicDailyTasks = UnmodifiableListView([
    ...quantitativeTasks,
    wipeCounterAndSweep,
    checkVerminTrap,
  ]);

  static final List<TaskList> dailyTasks = [
    TaskList(
      name: "Empty/Idle Room Daily Tasks",
      frequency: TaskFrequency.daily,
      tasks: quantitativeTasks,
    ),
    TaskList(
      name: "Surgery Room Daily Tasks",
      frequency: TaskFrequency.daily,
      tasks: basicDailyTasks,
    ),
    TaskList(
      name: "Storage Room Daily Tasks",
      frequency: TaskFrequency.daily,
      tasks: basicDailyTasks,
    ),
    TaskList(
      name: "Cagewash Room Daily Tasks",
      frequency: TaskFrequency.daily,
      tasks: UnmodifiableListView([
        ...quantitativeTasks,
        checkVerminTrap,
        Task(description: "Sweep"),
      ]),
    ),
    TaskList(
      name: "Animal Room Daily Tasks",
      frequency: TaskFrequency.daily,
      tasks: UnmodifiableListView([
        ...basicDailyTasks,
        Task(description: "View Each Animal"),
        Task(description: "Give/Check Food & Water"),
        Task(description: "Double Check Water"),
      ]),
    ),
    TaskList(
      name: "Hibernaculum Daily Tasks",
      frequency: TaskFrequency.daily,
      tasks: UnmodifiableListView([
        hibernaculumTempTask,
        hibernaculumHumidityTask,
        checkVerminTrap,
      ]),
    ),
  ];

  static final mopFloor = Task(description: "Mop Floor");
  static final managerWalkThroughTask = Task(
    description: "Manager Walkthrough",
  );

  static final basicWeeklyTasks = UnmodifiableListView([
    mopFloor,
    managerWalkThroughTask,
  ]);

  static final List<TaskList> weeklyTasks = [
    TaskList(
      name: "Empty/Idle Room Weekly Tasks",
      frequency: TaskFrequency.weekly,
      tasks: UnmodifiableListView([managerWalkThroughTask]),
    ),
    TaskList(
      name: "Storage Room Weekly Tasks",
      frequency: TaskFrequency.weekly,
      tasks: basicWeeklyTasks,
    ),
    TaskList(
      name: "Surgery Room Weekly Tasks",
      frequency: TaskFrequency.weekly,
      tasks: UnmodifiableListView([
        ...basicWeeklyTasks,
        Task(description: "Manager Check Expiration Dates on Drugs/Supplies"),
      ]),
    ),
    TaskList(
      name: "Cagewash Room Weekly Tasks",
      frequency: TaskFrequency.weekly,
      tasks: UnmodifiableListView([
        Task(description: "Perform Cage Wash Temp Strip Test"),
        ...basicWeeklyTasks,
      ]),
    ),
    TaskList(
      name: "Housing Weekly Tasks",
      frequency: TaskFrequency.weekly,
      tasks: UnmodifiableListView([
        Task(description: "Change Cage/Bedding"),
        Task(description: "Change Water Bottle"),
        Task(description: "Sanitize Enrichment"),
        Task(description: "Check Light Timer"),
        ...basicWeeklyTasks,
      ]),
    ),
  ];

  static final mopWallAndCeiling = Task(description: "Mop Walls and Ceiling");
  static final sanitizeShelvesRacksCarts = Task(
    description: "Sanitize Shelves/Racks/Carts",
  );
  static final sanitizeGarbageCan = Task(description: "Sanitize Garbage Can");
  static final sanitizeMopSupplies = Task(
    description: "Sanitize Mop Buckets & Cloth Mop Heads",
  );
  static final sanitizeDustPans = Task(description: "Sanitize Dust Pans");
  static final replaceDisinfectant = Task(description: "Replace Disinfectant");

  static final basicMonthlyTasks = UnmodifiableListView([
    mopWallAndCeiling,
    sanitizeShelvesRacksCarts,
    sanitizeGarbageCan,
    sanitizeMopSupplies,
    sanitizeDustPans,
    replaceDisinfectant,
  ]);

  static final List<TaskList> monthlyTasks = [
    TaskList(
      name: "Housing Monthly Tasks",
      frequency: TaskFrequency.monthly,
      tasks: UnmodifiableListView([
        ...basicMonthlyTasks,
        Task(
          description: "Check Function of Heaters or Dehumidifiers, If Present",
        ),
      ]),
    ),

    TaskList(
      name: "Storage Room Monthly Tasks",
      frequency: TaskFrequency.monthly,
      tasks: UnmodifiableListView([
        ...basicMonthlyTasks,
        Task(description: "Sanitize Storage Barrels & Scoops"),
        Task(description: "Sanitize Small Containers, If Present"),
        Task(description: "Refill Bins With Bedding, If Present"),
      ]),
    ),

    TaskList(
      name: "Cagewash Room Monthly Tasks",
      frequency: TaskFrequency.monthly,
      tasks: UnmodifiableListView([
        mopWallAndCeiling,
        Task(description: "Sanitize bedding disposal station"),
        Task(description: "Clean Sink With Comet, Then Spray With WD-40"),
        Task(description: "Wipe Cage Washer Exterior With WD-40"),
        Task(description: "Sanitize Water Bottle Filler"),
        Task(description: "Clean Paper Towel & Soap Dispensers"),
        Task(description: "Sanitize Garbage Cans, Including Any In Hallway"),
        sanitizeMopSupplies,
        sanitizeDustPans,
        replaceDisinfectant,
        Task(description: "Disinfect Drain Per Sign Taped to the Wall"),
      ]),
    ),

    TaskList(
      name: "Surgery Room Monthly Tasks",
      frequency: TaskFrequency.monthly,
      tasks: UnmodifiableListView([
        ...basicMonthlyTasks,
        Task(description: "Clean Sink With Comet"),
        Task(description: "Clean Paper Towel & Soap Dispensers"),
        Task(description: "Sanitize Storage Barrels & Scoops"),
        Task(description: "Sanitize Small Containers, If Present"),
        Task(description: "Refill Bins With Bedding, If Present"),
        Task(description: "Clean Refrigerator"),
        Task(description: "Check Euthanasia Equipment"),
        Task(description: "Check Anaesthesia Equipment"),
      ]),
    ),
  ];

  static final surgeryRoomDailies = TaskListRepository.dailyTasks[1];
  static final storageDailies = TaskListRepository.dailyTasks[2];
  static final cageRoomDailies = TaskListRepository.dailyTasks[3];
  static final housingRoomDailies = TaskListRepository.dailyTasks[4];
  static final hibernaculumDailies = TaskListRepository.dailyTasks[5];
  
  static final Map<String, TaskList> roomToDailyTaskLists = {
    "CACF 36B": housingRoomDailies, // 0
    "CACF 36C": housingRoomDailies, // 1
    "CACF 36D": housingRoomDailies, // 2
    "CACF 36E": housingRoomDailies, // 3
    "CACF 36F": housingRoomDailies, // 4
    "CACF 36G": storageDailies, // 5
    "CACF 36H": housingRoomDailies, // 6
    "CACF 36J": surgeryRoomDailies, // 7
    "CACF 36K": surgeryRoomDailies, // 8
    "CACF 36L": cageRoomDailies, // 9
    "HACF 17": storageDailies, // 10
    "HACF 19A": housingRoomDailies, // 11
    "HACF 19B": housingRoomDailies, // 12
    "HACF 19C": housingRoomDailies, // 13
    "HACF 19D": hibernaculumDailies, // 14
    "HACF 19E/F": cageRoomDailies, // 15
    "HACF 19G": surgeryRoomDailies, // 16
    "HACF 19H": housingRoomDailies, // 17
    "HACF 19J": housingRoomDailies, // 18
    "HACF 56A": hibernaculumDailies, // 19
  };

  static final surgeryRoomWeeklies = TaskListRepository.weeklyTasks[2];
  static final storageWeeklies = TaskListRepository.weeklyTasks[1];
  static final cageRoomWeeklies = TaskListRepository.weeklyTasks[3];
  static final housingRoomWeeklies = TaskListRepository.weeklyTasks[4];
  static final hibernaculumWeeklies = TaskListRepository.weeklyTasks[4];
  
  static final Map<String, TaskList> roomToWeeklyTaskLists = {
    "CACF 36B": housingRoomWeeklies,
    "CACF 36C": housingRoomWeeklies,
    "CACF 36D": housingRoomWeeklies,
    "CACF 36E": housingRoomWeeklies,
    "CACF 36F": housingRoomWeeklies,
    "CACF 36G": storageWeeklies,
    "CACF 36H": housingRoomWeeklies,
    "CACF 36J": surgeryRoomWeeklies,
    "CACF 36K": surgeryRoomWeeklies,
    "CACF 36L": cageRoomWeeklies,
    "HACF 17": storageWeeklies,
    "HACF 19A": housingRoomWeeklies,
    "HACF 19B": housingRoomWeeklies,
    "HACF 19C": housingRoomWeeklies,
    "HACF 19D": hibernaculumWeeklies,
    "HACF 19E/F": cageRoomWeeklies,
    "HACF 19G": surgeryRoomWeeklies,
    "HACF 19H": housingRoomWeeklies,
    "HACF 19J": housingRoomWeeklies,
    "HACF 56A": hibernaculumWeeklies,
  };

  static final surgeryRoomMonthlies = TaskListRepository.monthlyTasks[3];
  static final storageMonthlies = TaskListRepository.monthlyTasks[1];
  static final cageRoomMonthlies = TaskListRepository.monthlyTasks[3];
  static final housingRoomMonthlies = TaskListRepository.monthlyTasks[0];
  static final hibernaculumMonthlies = TaskListRepository.monthlyTasks[0];

  static final Map<String, TaskList> roomToMonthlyTaskLists = {
    "CACF 36B": housingRoomMonthlies,
    "CACF 36C": housingRoomMonthlies,
    "CACF 36D": housingRoomMonthlies,
    "CACF 36E": housingRoomMonthlies,
    "CACF 36F": housingRoomMonthlies,
    "CACF 36G": storageMonthlies,
    "CACF 36H": housingRoomMonthlies,
    "CACF 36J": surgeryRoomMonthlies,
    "CACF 36K": surgeryRoomMonthlies,
    "CACF 36L": cageRoomMonthlies,
    "HACF 17": storageMonthlies,
    "HACF 19A": housingRoomMonthlies,
    "HACF 19B": housingRoomMonthlies,
    "HACF 19C": housingRoomMonthlies,
    "HACF 19D": hibernaculumMonthlies,
    "HACF 19E/F": cageRoomMonthlies,
    "HACF 19G": surgeryRoomMonthlies,
    "HACF 19H": housingRoomMonthlies,
    "HACF 19J": housingRoomMonthlies,
    "HACF 56A": hibernaculumMonthlies,
  };

}
