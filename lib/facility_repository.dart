import 'package:animal_room_task_manager/supabase_client/database.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Facility{
  final int fid;
  final String name;

  Facility({required this.fid, required this.name});

}

class FacilityRepository extends ChangeNotifier {
  Database database;

  FacilityRepository({required this.database}) {
    database.subscribeToFacilities((PostgresChangePayload p) {
      var p1 = p;
    });
  }
}

