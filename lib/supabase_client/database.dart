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

  void subscribeToEmailWhitelist(
    void Function(PostgresChangePayload) callback,
  ) {
    _supabase
        .channel("email_whitelist")
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'email_whitelist',
          callback: callback,
        )
        .subscribe();
  }

  void subscribeToUsers(void Function(PostgresChangePayload) callback) {
    _supabase
        .channel("users")
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'users',
          callback: callback,
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

  Future<PostgrestMap> getRoomCheckWithId(int rcid) async {
    return await _supabase
        .from('full_room_checks_view')
        .select()
        .eq('rc_id', rcid)
        .single();
  }

  Future<int> getRoomCheckRcid(RoomCheckSlot roomCheckSlot) async {
    return (await _supabase
        .from('room_check_slots')
        .select('rc_id')
        .eq('r_id', roomCheckSlot.room.rid)
        .eq('date_time', roomCheckSlot.date.toSupabaseString())
        .eq('frequency', roomCheckSlot.frequency.toDbString)
        .single())['rc_id'];
  }

  Future<List<PostgrestMap>> getUsers() async {
    final data = await _supabase.from('users').select('''
    *
  ''');
    return data.toList();
  }

  Future<List<PostgrestMap>> getWhitelistedEmails() async {
    final data = await _supabase.from('email_whitelist').select('''
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

  // inserts/updates
  // ---------------------------------------------------------------------------
  Future<int> upsert<T>({
    required int? id,
    required T object,
    required Future<void> Function(T, int) doUpdate,
    required Future<int> Function(T) doInsert,
    required Future<int> Function(T) doSelect,
  }) async {
    if (id != null) {
      // if id is not null, then the row is already in the database
      await doUpdate(object, id);
      return id;
    } else {
      try {
        return await doInsert(object);
      } on PostgrestException catch (ex, e) {
        if (ex.message.contains("duplicate key")) {
          id = await doSelect(object);
          await doUpdate(object, id);
          return id;
        } else {
          rethrow;
        }
      }
    }
  }

  Future<int> insertRoomCheckAndGetRcid(RoomCheckSlot roomCheckSlot) async {
    return (await _supabase
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
        .single())['rc_id'];
  }

  Future<void> updateRoomCheck(RoomCheckSlot roomCheckSlot, int id) async {
    await _supabase
        .from('room_check_slots')
        .update({
          'state': roomCheckSlot.state.toDbString,
          'comment': roomCheckSlot.comment,
          'u_id': roomCheckSlot.user?.uid,
        })
        .eq('rc_id', id);
  }

  Future<int> upsertRoomCheckAndGetRcid(RoomCheckSlot roomCheckSlot) async {
    return await upsert(
      id: roomCheckSlot.rcid,
      object: roomCheckSlot,
      doUpdate: updateRoomCheck,
      doInsert: insertRoomCheckAndGetRcid,
      doSelect: getRoomCheckRcid,
    );
  }

  Future<void> updateUserGroup(ur.User user) async {
    await _supabase
        .from('email_whitelist')
        .update({'ug_id': user.group.index})
        .eq('email', user.email);
    await _supabase
        .from('users')
        .update({'ug_id': user.group.index})
        .eq('u_id', user.uid!);
  }

  Future<void> removeUser(ur.User user) async {
    await _supabase
        .from('users')
        .update({'deleted': true})
        .eq('u_id', user.uid!);
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

  Future<void> addUserToWhitelist(ur.User user) async {
    await _supabase.from(roomCheckTableName).insert({
      'email',
      user.email,
      'ug_id',
      user.group.index,
    });
  }
}
