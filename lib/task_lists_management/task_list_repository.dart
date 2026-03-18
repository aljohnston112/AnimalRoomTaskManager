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
  final List<Task> tasks;

  TaskList({required this.name, required this.frequency, required this.tasks});
}

class TaskListRepository {

  static final tempTask = QuantitativeTask(
    description: "Room Temperature",
    range: QuantitativeRange(min: 20, max: 24, units: "Fahrenheit"),
  );

  static final hibernaculumTempTask = QuantitativeTask(
    description: "Room Temperature",
    range: QuantitativeRange(min: 2, max: 8, units: "Fahrenheit"),
  );

  static final humidityTask = QuantitativeTask(
    description: "Room Humidity",
    range: QuantitativeRange(min: 30, max: 60, units: "RH"),
  );

  static final hibernaculumHumidityTask = QuantitativeTask(
    description: "Room Humidity",
    range: QuantitativeRange(min: 70, max: 95, units: "RH"),
  );

  static final managerWalkThroughTask = Task(
    description: "Manager Walkthrough",
  );

  final List<TaskList> dailyTasks = [
    TaskList(
      name: "CACF Surgery Room Daily Tasks",
      frequency: TaskFrequency.daily,
      tasks: [
        tempTask,
        humidityTask,
        Task(description: "Wipe Counters & Sweep"),
        Task(description: "Check Vermin Trap"),
      ],
    ),
    TaskList(
      name: "CACF Empty/Idle Room Daily Tasks",
      frequency: TaskFrequency.daily,
      tasks: [tempTask, humidityTask],
    ),
    TaskList(
      name: "CACF Storage Room Daily Tasks",
      frequency: TaskFrequency.daily,
      tasks: [
        tempTask,
        humidityTask,
        Task(description: "Wipe Counters & Sweep"),
        Task(description: "Check Vermin Trap"),
      ],
    ),
    TaskList(
      name: "HACF Animal Room Daily Tasks",
      frequency: TaskFrequency.daily,
      tasks: [
        tempTask,
        humidityTask,
        Task(description: "View Each Animal"),
        Task(description: "Give/Check Food & Water"),
        Task(description: "Wipe Counters & Sweep"),
        Task(description: "Check Vermin Trap"),
        Task(description: "Double Check Water")
      ],
    ),
    TaskList(
      name: "CACF Cagewash Room Daily Tasks",
      frequency: TaskFrequency.daily,
      tasks: [
        tempTask,
        humidityTask,
        Task(description: "Sweep"),
        Task(description: "Check Vermin Trap"),
      ],
    ),
  ];

  final List<TaskList> weeklyTasks = [
    TaskList(
      name: "CACF Surgery Room Weekly Tasks",
      frequency: TaskFrequency.weekly,
      tasks: [
        Task(description: "Mop Floor"),
        managerWalkThroughTask,
        Task(description: "Manager Check Expiration Dates on Drugs/Supplies"),
      ],
    ),
    TaskList(
      name: "CACF Empty/Idle Room Weekly Tasks",
      frequency: TaskFrequency.weekly,
      tasks: [managerWalkThroughTask],
    ),
    TaskList(
      name: "CACF Storage Room Weekly Tasks",
      frequency: TaskFrequency.weekly,
      tasks: [
        Task(description: "Mop Floor"),
        managerWalkThroughTask,
      ],
    ),
    TaskList(
      name: "HACF Storage Room Weekly Tasks",
      frequency: TaskFrequency.weekly,
      tasks: [
        Task(description: "Change Cage/Bedding"),
        Task(description: "Change Water Bottle"),
        Task(description: "Sanitize Enrichment"),
        Task(description: "Check Light Timer"),
        Task(description: "Mop Floor"),
        managerWalkThroughTask,
      ],
    ),
    TaskList(
      name: "CACF Storage Room Weekly Tasks",
      frequency: TaskFrequency.weekly,
      tasks: [
        Task(description: "Perform Cage Wash Temp Strip Test"),
        Task(description: "Mop Floor"),
        managerWalkThroughTask,
      ],
    ),
  ];

  final List<TaskList> monthlyTasks = [
    TaskList(
      name: "CACF Surgery Room Monthly Tasks",
      frequency: TaskFrequency.monthly,
      tasks: [
        Task(description: "Mop Walls and Ceiling"),
        Task(description: "Sanitize Shelves/Racks/Carts"),
        Task(description: "Clean Sink With Comet"),
        Task(description: "Clean Paper Towel & Soap Dispensers"),
        Task(description: "Sanitize Garbage Can"),
        Task(description: "Sanitize Mop Buckets & Cloth Mop Heads"),
        Task(description: "Sanitize Storage Barrels & Scoops"),
        Task(description: "Sanitize Small Containers, If Present"),
        Task(description: "Sanitize Dust Pans"),
        Task(description: "Replace Disinfectant"),
        Task(description: "Refill Bins With Bedding, If Present"),
        Task(description: "Clean Refrigerator"),
        Task(description: "Check Euthanasia Equipment"),
        Task(description: "Check Anaesthesia Equipment"),
      ],
    ),
    TaskList(
      name: "CACF Storage Room Monthly Tasks",
      frequency: TaskFrequency.monthly,
      tasks: [
        Task(description: "Mop Walls and Ceiling"),
        Task(description: "Sanitize Shelves/Racks/Carts"),
        Task(description: "Sanitize Garbage Can"),
        Task(description: "Sanitize Mop Buckets & Cloth Mop Heads"),
        Task(description: "Sanitize Storage Barrels & Scoops"),
        Task(description: "Sanitize Small Containers, If Present"),
        Task(description: "Sanitize Dust Pans"),
        Task(description: "Replace Disinfectant"),
        Task(description: "Refill Bins With Bedding, If Present"),
      ],
    ),
    TaskList(
      name: "HACF Animal Room Monthly Tasks",
      frequency: TaskFrequency.monthly,
      tasks: [
        Task(description: "Mop Walls and Ceiling"),
        Task(description: "Sanitize Shelves/Racks/Carts"),
        Task(description: "Sanitize Garbage Can"),
        Task(description: "Sanitize Mop Buckets & Cloth Mop Heads"),
        Task(description: "Sanitize Dust Pans"),
        Task(description: "Replace Disinfectant"),
        Task(
          description: "Check Function of Heaters or Dehumidifiers, If Present",
        ),
      ],
    ),
    TaskList(
      name: "CACF Cagewasher Room Monthly Tasks",
      frequency: TaskFrequency.monthly,
      tasks: [
        Task(description: "Mop Walls and Ceiling"),
        Task(description: "Sanitize bedding disposal station"),
        Task(description: "Clean Sink With Comet, Then Spray With WD-40"),
        Task(description: "Wipe Cage Washer Exterior With WD-40"),
        Task(description: "Sanitize Water Bottle Filler"),
        Task(description: "Clean Paper Towel & Soap Dispensers"),
        Task(description: "Sanitize Garbage Cans, Including Any In Hallway"),
        Task(description: "Sanitize Mop Buckets & Cloth Mop Heads"),
        Task(description: "Sanitize Dust Pans"),
        Task(description: "Replace Disinfectant"),
        Task(description: "Disinfect Drain Per Sign Taped to the Wall")
      ],
    ),
  ];
}
