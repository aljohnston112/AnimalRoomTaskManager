import 'dart:collection';

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

class TaskList {
  final String name;
  final TaskFrequency frequency;
  final UnmodifiableListView<Task> tasks;

  TaskList({required this.name, required this.frequency, required this.tasks});
}

class TaskListRepository {
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
        wipeCounterAndSweep,
        checkVerminTrap,
        Task(description: "View Each Animal"),
        Task(description: "Give/Check Food & Water"),
        Task(description: "Double Check Water"),
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
      name: "Storage Room Weekly Tasks",
      frequency: TaskFrequency.weekly,
      tasks: UnmodifiableListView([
        Task(description: "Perform Cage Wash Temp Strip Test"),
        ...basicWeeklyTasks,
      ]),
    ),
    TaskList(
      name: "Storage Room Weekly Tasks",
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
      name: "Animal Room Monthly Tasks",
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
      name: "Cagewasher Room Monthly Tasks",
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
}
