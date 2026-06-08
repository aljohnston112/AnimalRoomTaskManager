import 'dart:collection';

import 'package:animal_room_task_manager/scheduler/scheduling_model.dart';
import 'package:flutter/material.dart';

import '../building_management/building_repository.dart';
import '../theme_data.dart';

class SchedulerBuildingSelectorScreen extends StatelessWidget {
  final String title;
  final SplayTreeMap<Building, List<Widget>> children;
  final SchedulingModel model;

  const SchedulerBuildingSelectorScreen({
    super.key,
    required this.title,
    required this.children,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    final buildings = children.keys.toList();
    return Column(
      children: [
        Expanded(
          child: ListenableBuilder(
            listenable: model.currentBuildingListenable,
            builder: (context, _) {
              if (model.currentBuilding == null) {
                return constrainToPhoneWidth(
                  ListView.separated(
                    padding: insets8,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    shrinkWrap: true,
                    itemCount: buildings.length,
                    itemBuilder: (context, index) {
                      final building = buildings[index];
                      return Card(
                        child: ListTile(
                          trailing: Icon(Icons.chevron_right),
                          title: Text(building.name),
                          onTap: () {
                            model.buildingClicked(building);
                          },
                        ),
                      );
                    },
                  ),
                );
              } else {
                return Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: insets8,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: children[model.currentBuilding]!,
                            ),
                          );
                        },
                      ),
                    ),
                    padding8,
                  ],
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
