import 'package:animal_room_task_manager/scheduler/scheduling_model.dart';
import 'package:animal_room_task_manager/scheduler/scheduling_screen_cards.dart';
import 'package:flutter/material.dart';

import '../task_lists_management/task_list_repository.dart';
import '../theme_data.dart';

class SchedulingHomeScreen extends StatelessWidget {
  final SchedulingModel schedulingModel;

  const SchedulingHomeScreen({super.key, required this.schedulingModel});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Scheduler"),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Daily"),
              Tab(text: "Weekly"),
              Tab(text: "Monthly"),
            ],
          ),
        ),
        body: SafeArea(
          child: pad8(
            Column(
              children: [
                Expanded(
                  child: TabBarView(
                    children: [
                      SchedulingScreenCards(
                        taskFrequency: TaskFrequency.daily,
                        schedulingModel: schedulingModel,
                      ),
                      SchedulingScreenCards(
                        taskFrequency: TaskFrequency.weekly,
                        schedulingModel: schedulingModel,
                      ),
                      SchedulingScreenCards(
                        taskFrequency: TaskFrequency.monthly,
                        schedulingModel: schedulingModel,
                      ),
                    ],
                  ),
                ),
                pad8(
                  FilledButton(
                    onPressed: () async {
                      unNavigate();
                    },
                    child: const Text("Go Back"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
