import 'package:animal_room_task_manager/supabase_client/database.dart';

import 'census_model.dart';

class CensusRepository {
  final Database _database;

  CensusRepository({required Database database}) : _database = database;

  Future<void> submitCensus(
    List<Census> censusEntries,
    int rid,
    int uid,
  ) async {
    await _database.submitCensus(censusEntries, rid, uid);
  }
}
