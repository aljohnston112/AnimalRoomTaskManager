import 'package:animal_room_task_manager/room_check/record_repository.dart';
import 'package:animal_room_task_manager/room_check/room_check_repository.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../user_management/user_repository.dart' as ur;

class InsertAndGetKeyResult {
  late bool inserted;
  late int key;

  InsertAndGetKeyResult({required this.inserted, required this.key});
}

class Database {
  final SupabaseClient _supabase;
  final roomCheckTableName = "room_check_slots";

  Database._(this._supabase);

  static Future<Database> create() async {
    final connection = await Supabase.initialize(
      url: 'https://rlbbezekxurjffutovsz.supabase.co',
      anonKey: 'sb_publishable_tPiZgEloifhv8Af6sG_m1w_-mEQ1RnT',
      authOptions: const FlutterAuthClientOptions(
        // TODO for dev only
        localStorage: EmptyLocalStorage(),
      ),
    );
    return Database._(connection.client);
  }

  Future<bool> signUp({required String email, required String password}) async {
    // if signUp succeeds,
    // then the users table has been populated with the signed in user
    AuthResponse response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    if (response.session == null) {
      return false;
    }
    return true;
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      return true;
    } on AuthApiException {
      return false;
    }
  }

  // Subscriptions
  // ---------------------------------------------------------------------------
  void subscribeToAuth(void Function(AuthState) onAuthChange) {
    _supabase.auth.onAuthStateChange.listen((data) {
      onAuthChange(data);
    });
  }

  void subscribeToFacilities(void Function(PostgresChangePayload) callback) {
    _supabase
        .channel("facilities")
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'facilities',
          callback: callback,
        )
        .subscribe();
  }

  void subscribeToRoomChecks(void Function(PostgresChangePayload) callback) {
    _supabase
        .channel(roomCheckTableName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: roomCheckTableName,
          callback: callback,
        )
        .subscribe();
  }

  void subscribeToRecords(void Function(dynamic) callback) {
    final taskRecordChannel = _supabase.channel(
      'task_record_channel',
      opts: const RealtimeChannelConfig(private: true),
    );
    taskRecordChannel
        .onBroadcast(
          event: 'task_recorded',
          callback: (payload) {
            callback(payload);
          },
        )
        .subscribe();
  }

  // selectors
  // ---------------------------------------------------------------------------
  Future<List<PostgrestMap>> getRecords() async {
    final today = DateTime.now();
    final startOfToday = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();
    final List<PostgrestMap> data = await _supabase.rpc(
      'get_task_records',
      params: {'start_date': startOfToday},
    );
    return data;
  }

  Future<List<PostgrestMap>> getRoomCheckSlots() async {
    final today = DateTime.now();
    final startOfToday = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();
    final List<PostgrestMap> data = await _supabase.rpc(
      'get_room_check_slots',
      params: {'start_date': startOfToday},
    );
    return data;
  }

  Future<List<PostgrestMap>> getTaskLists() async {
    final data = await _supabase.from('room_check_task_lists_view').select('''
    *
  ''');
    return data.toList();
  }

  ur.UserGroup _getUserGroup(PostgrestMap postgresMap) {
    switch (postgresMap['ug_id']) {
      case 0:
        return ur.UserGroup.admin;
      case 1:
        return ur.UserGroup.principalInvestigatorOrChiefOfStaff;
      case 2:
        return ur.UserGroup.roomChecker;
    }
    throw Exception("Invalid user group");
  }

  Future<ur.User?> getUserWithAuthId(String authId) async {
    final userResponse = await _supabase
        .from('users')
        .select('*')
        .eq('auth_id', authId)
        .maybeSingle();
    if (userResponse != null) {
      return ur.User(
        email: userResponse['name'],
        group: _getUserGroup(userResponse),
        uid: userResponse['u_id'],
      );
    }
    return null;
  }

  Future<PostgrestMap> getRoomCheckWithId(int rcid) async {
    return await _supabase
        .from('full_room_checks_view')
        .select()
        .eq('rc_id', rcid)
        .single();
  }

  Future<int> getRoomCheckRCID(
    RoomCheckDate date,
    int rid,
    TaskFrequency frequency,
  ) async {
    return (await _supabase
        .from('room_check_slots')
        .select('rc_id')
        .eq('r_id', rid)
        .eq('date_time', date.toSupabaseString())
        .eq('frequency', frequency.toDbString)
        .single())['rc_id'];
  }

  // inserts/updates
  // ---------------------------------------------------------------------------
  Future<InsertAndGetKeyResult> tryInsertRoomCheckAndGetID(
    RoomCheckSlot roomCheckSlot,
  ) async {
    try {
      return InsertAndGetKeyResult(
        inserted: true,
        key: (await _supabase
            .from(roomCheckTableName)
            .insert({
              'date_time': roomCheckSlot.date.toSupabaseString(),
              'r_id': roomCheckSlot.room.rid,
              'state': roomCheckSlot.state.toDbString,
              'frequency': roomCheckSlot.frequency.toDbString,
              'comment': roomCheckSlot.comment,
              'u_id': roomCheckSlot.user?.uid,
            })
            .select('rc_id')
            .single())['rc_id'],
      );
    } on PostgrestException catch (ex, e) {
      if (ex.message.contains("duplicate key")) {
        return InsertAndGetKeyResult(
          inserted: false,
          key: await getRoomCheckRCID(
            roomCheckSlot.date,
            roomCheckSlot.room.rid,
            roomCheckSlot.frequency,
          ),
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> assignUserToRoomCheck(RoomCheckSlot roomCheckSlot) async {
    final rcid = roomCheckSlot.rcid;
    if (rcid != null) {
      await _supabase
          .from(roomCheckTableName)
          .update({'u_id': roomCheckSlot.user?.uid})
          .eq('rc_id', rcid);
    } else {
      // this is needed since there may be a race condition between a
      // room check slot getting pushed to supabase and downloaded,
      // and when trying to insert a room check with a new assignment
      final result = await tryInsertRoomCheckAndGetID(roomCheckSlot);
      final rcid = result.key;
      if (!result.inserted) {
        await _supabase
            .from(roomCheckTableName)
            .update({'u_id': roomCheckSlot.user?.uid})
            .eq('rc_id', rcid);
      }
    }
  }

  Future<void> upsertRoomCheck(RoomCheckSlot roomCheckSlot) async {
    var rcid = roomCheckSlot.rcid;
    if (rcid != null) {
      await _supabase
          .from('room_check_slots')
          .update({
            'state': roomCheckSlot.state.toDbString,
            'comment': roomCheckSlot.comment,
            'u_id': roomCheckSlot.user?.uid,
          })
          .eq('rc_id', rcid);
    } else {
      final result = await tryInsertRoomCheckAndGetID(roomCheckSlot);
      final rcid = result.key;
      if (!result.inserted) {
        await _supabase
            .from('room_check_slots')
            .update({
              'state': roomCheckSlot.state.toDbString,
              'comment': roomCheckSlot.comment,
              'u_id': roomCheckSlot.user?.uid,
            })
            .eq('rc_id', rcid);
      }
    }
  }

  Future<bool> insertRecord(TaskRecord taskRecord) async {
    // TODO this will fail if the task is already recorded
    double? value;
    if (taskRecord is QuantitativeRecord) {
      value = taskRecord.recordedValue;
    }
    await _supabase.rpc(
      'submit_task_record',
      params: {
        'record_data': {
          't_id': taskRecord.task.tid,
          'rc_id': taskRecord.rcid,
          'date_time': taskRecord.dateTime.toIso8601String(),
        },
        // TODO List<USer>
        'user_ids': [taskRecord.doneBy.uid],
        'recorded_value': value,
      },
    );
    return true;
  }
}
