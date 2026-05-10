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
    return buildScaffold(
      title: "Scheduler",
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildDailySchedulingButton(context),
          _buildWeeklySchedulingButton(context),
          _buildMonthlySchedulingButton(context),
          FilledButton(
            onPressed: () async {
              unNavigate();
            },
            child: Text("Go Back"),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySchedulingButton(BuildContext context) {
    return FilledButton(
      child: Text("Daily"),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SchedulingScreenCards(
              taskFrequency: TaskFrequency.daily,
              schedulingModel: schedulingModel,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklySchedulingButton(BuildContext context) {
    return FilledButton(
      child: Text("Weekly"),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SchedulingScreenCards(
              taskFrequency: TaskFrequency.weekly,
              schedulingModel: schedulingModel,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlySchedulingButton(BuildContext context) {
    return FilledButton(
      child: Text("Monthly"),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SchedulingScreenCards(
              taskFrequency: TaskFrequency.monthly,
              schedulingModel: schedulingModel,
            ),
          ),
        );
      },
    );
  }
}
