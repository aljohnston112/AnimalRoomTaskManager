import 'package:animal_room_task_manager/animal_management/animal_repository.dart';
import 'package:animal_room_task_manager/building_management/building_repository.dart';
import 'package:animal_room_task_manager/census/census_model.dart';
import 'package:animal_room_task_manager/lab_management/lab_repository.dart';
import 'package:animal_room_task_manager/room_check/record_repository.dart';
import 'package:animal_room_task_manager/room_check/room_check_repository.dart';
import 'package:animal_room_task_manager/scheduler/scheduling_model.dart';
import 'package:animal_room_task_manager/task_lists_management/task_list_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../facility_management/facility_repository.dart';
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
      authOptions: const FlutterAuthClientOptions(),
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

  bool isSessionValid() {
    if (_supabase.auth.currentSession != null) {
      return true;
    }
    return false;
  }

  User? getSessionUser() {
    return _supabase.auth.currentUser;
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

  void subscribeToAnimals(Null Function(PostgresChangePayload p) callback) {
    _supabase
        .channel("animals")
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'animals',
          callback: callback,
        )
        .subscribe();
  }

  void subscribeToBuildings(Null Function(PostgresChangePayload p) callback) {
    _supabase
        .channel("buildings")
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'buildings',
          callback: callback,
        )
        .subscribe();
  }

  void subscribeToLabs(void Function(PostgresChangePayload p) callback) {
    _supabase
        .channel("labs")
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'labs',
          callback: callback,
        )
        .subscribe();
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

  void subscribeToRoomsUpdates(void Function(dynamic) callback) {
    _supabase
        .channel("rooms")
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'rooms',
          callback: callback,
        )
        .subscribe();
  }

  void subscribeToFullRooms(void Function(dynamic) callback) {
    _supabase
        .channel(
          'room_channel',
          opts: const RealtimeChannelConfig(private: true),
        )
        .onBroadcast(event: 'room_update', callback: callback)
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

  void subscribeToTaskListsFull(void Function(dynamic) callback) {
    final taskRecordChannel = _supabase.channel(
      'task_list_channel',
      opts: const RealtimeChannelConfig(private: true),
    );
    taskRecordChannel
        .onBroadcast(
          event: 'task_list_update',
          callback: (payload) {
            callback(payload);
          },
        )
        .subscribe();
  }

  void subscribeToTaskLists(void Function(PostgresChangePayload) callback) {
    _supabase
        .channel("task_lists")
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'task_lists',
          callback: callback,
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
  Future<List<PostgrestMap>> getAnimals() async {
    final data = await _supabase.from('animals').select('''
    *
  ''');
    return data.toList();
  }

  Future<List<PostgrestMap>> getBuildings() async {
    final data = await _supabase.from('buildings').select('''
    *
  ''');
    return data.toList();
  }

  Future<List<PostgrestMap>> getLabs() async {
    final data = await _supabase.from('labs').select('''
    *
  ''');
    return data.toList();
  }

  Future<List<PostgrestMap>> getFacilities() async {
    final data = await _supabase.from('facilities').select('''
    *
  ''');
    return data.toList();
  }

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

  Future<List<PostgrestMap>> getRecordsForRoom(
    Room room,
    RoomCheckDate date,
    TaskFrequency frequency,
  ) async {
    final List<PostgrestMap> data = await _supabase.rpc(
      'get_task_records_for_room',
      params: {
        'rid': room.rid,
        'date': date.toSupabaseString(),
        'task_frequency': frequency.toDbString,
      },
    );
    return data;
  }

  Future<List<PostgrestMap>> getRecordsForMonth(DateTime date) async {
    final start = DateTime(date.year, date.month).toIso8601String();
    final end = DateTime(date.year, date.month + 1).toIso8601String();
    return await _supabase
        .from('all_task_records_view')
        .select()
        .gte('recorded_date', start)
        .lt('recorded_date', end);
  }

  Future<List<PostgrestMap>> getRooms() async {
    return await _supabase.rpc('get_rooms_full');
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

  Future<List<PostgrestMap>> getTasks() async {
    final data = await _supabase.from('all_tasks_view').select('''
    *
  ''');
    return data.toList();
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

  // TODO unique constraints on tasks and ranges

  Future<int> addRange(QuantitativeRange<double> range) async {
    try {
      return (await _supabase
          .from('quantitative_ranges')
          .insert({
            'unit': range.units,
            'maximum': range.max,
            'minimum': range.min,
            'deleted': false,
          })
          .select('qr_id')
          .single())['qr_id'];
    } on PostgrestException catch (ex, e) {
      if (ex.message.contains("duplicate key")) {
        // TODO this is fine,
        //      but ranges need to be implemented client side to avoid
        return (await _supabase
            .from('quantitative_ranges')
            .select('qr_id')
            .eq('unit', range.units)
            .eq('maximum', range.max)
            .eq('minimum', range.min)
            .single())['qr_id'];
      } else {
        rethrow;
      }
    }
  }

  // TODO undelete tasks and ranges on duplicate
  // TODO realtime update of tasks

  Future<void> addQuantitativeTask(
    String description,
    bool isManagerOnly,
    QuantitativeRange<double>? warningRange,
    QuantitativeRange<double>? requiredRange,
  ) async {
    int tid = await addTask(description, isManagerOnly);
    int? qridWarning;
    int? qridRequired;
    if (warningRange != null) {
      qridWarning = await addRange(warningRange);
    }
    if (requiredRange != null) {
      qridRequired = await addRange(requiredRange);
    }
    try {
      return (await _supabase.from('quantitative_tasks').insert({
        't_id': tid,
        'qr_id_warning': qridWarning,
        'qr_id_required': qridRequired,
      }));
    } on PostgrestException catch (ex, e) {
      if (ex.message.contains("duplicate key")) {
        // TODO this is fine,
        //      but ranges need to be implemented client side to avoid
      } else {
        rethrow;
      }
    }
  }

  Future<int> addTask(String description, bool isManagerOnly) async {
    try {
      return (await _supabase
          .from('tasks')
          .insert({
            'name': description,
            'manager_only': isManagerOnly,
            'deleted': false,
          })
          .select('t_id')
          .single())['t_id'];
    } on PostgrestException catch (ex, e) {
      if (ex.message.contains("duplicate key")) {
        // this is fine, and should be avoided client side
        // TODO undelete
        return (await _supabase
            .from('tasks')
            .select('t_id')
            .eq('name', description)
            .eq('manager_only', isManagerOnly)
            .single())['t_id'];
      } else {
        rethrow;
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
        // TODO List<User>
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

  Future<void> insertAnimal(String animalName) async {
    try {
      return (await _supabase
          .from('animals')
          .insert({'name': animalName, 'deleted': false})
          .select('a_id')
          .single())['a_id'];
    } on PostgrestException catch (ex, e) {
      if (ex.message.contains("duplicate key")) {
        // Front end does not have deleted rows
        // therefore toggling the deleted flag
        await undeleteAnimal(animalName);
      } else {
        rethrow;
      }
    }
  }

  Future<void> insertLab(String labName, int color) async {
    try {
      return (await _supabase
          .from('labs')
          .insert({'name': labName, 'color': color, 'deleted': false})
          .select('l_id')
          .single())['l_id'];
    } on PostgrestException catch (ex, e) {
      if (ex.message.contains("duplicate key")) {
        // Front end does not have deleted rows
        // therefore toggling the deleted flag
        await undeleteLab(labName);
      } else {
        rethrow;
      }
    }
  }

  Future<void> insertBuilding(String buildingName) async {
    try {
      return (await _supabase
          .from('buildings')
          .insert({'name': buildingName, 'deleted': false})
          .select('b_id')
          .single())['b_id'];
    } on PostgrestException catch (ex, e) {
      if (ex.message.contains("duplicate key")) {
        // Front end does not have deleted rows
        // therefore toggling the deleted flag
        await undeleteBuilding(buildingName);
      } else {
        rethrow;
      }
    }
  }

  Future<void> submitCensus(List<Census> censusEntries, int uid) async {
    await _supabase.rpc(
      'submit_census',
      params: {
        'uid': uid,
        'census_records': censusEntries
            .map(
              (e) => {
                'a_id': e.animal.aid,
                'quantity': e.quantity,
                'r_id': e.room.rid,
              },
            )
            .toList(),
      },
    );
  }

  Future<void> insertFacility(String facilityName) async {
    try {
      return (await _supabase
          .from('facilities')
          .insert({'name': facilityName, 'deleted': false})
          .select('f_id')
          .single())['f_id'];
    } on PostgrestException catch (ex, e) {
      if (ex.message.contains("duplicate key")) {
        // Front end does not have deleted rows
        // therefore toggling the deleted flag
        await undeleteFacility(facilityName);
      } else {
        rethrow;
      }
    }
  }

  Future<void> insertRoom({
    required String roomName,
    required int lid,
    required int fid,
    required int bid,
    required List<int> tlids,
  }) async {
    await _supabase.rpc(
      'insert_room',
      params: {
        'room_name': roomName,
        'lid': lid,
        'fid': fid,
        'bid': bid,
        'tlids': tlids,
      },
    );
  }

  Future<void> updateRoom({
    required int rid,
    required int lid,
    required List<int> tlids,
  }) async {
    await _supabase.rpc(
      'update_room',
      params: {'rid': rid, 'lid': lid, 'tlids': tlids},
    );
  }

  Future<void> insertTaskList(
    String taskListName,
    TaskFrequency frequency,
    Map<int, int> tidToIndex,
  ) async {
    await _supabase.rpc(
      'insert_task_list',
      params: {
        'name_in': taskListName,
        'frequency_in': frequency.toDbString,
        'task_list_task_membership_rows': tidToIndex.entries.map((e) {
          return {'t_id': e.key, 'index': e.value};
        }).toList(),
      },
    );
  }

  Future<void> editTaskList(
    int tlid,
    String taskListName,
    TaskFrequency frequency,
    Map<int, int> tidToIndex,
  ) async {
    await _supabase.rpc(
      'edit_task_list',
      params: {
        'old_tl_id': tlid,
        'name': taskListName,
        'frequency': frequency.toDbString,
        'task_list_task_membership_rows': tidToIndex.entries.map((e) {
          return {'t_id': e.key, 'index': e.value};
        }).toList(),
      },
    );
  }

  Future<void> reorderTasks(int tlid, Map<int, int> tidToIndex) async {
    await _supabase.rpc(
      'reorder_tasks',
      params: {
        'payload': tidToIndex.entries.map((e) {
          return {'tl_id': tlid, 't_id': e.key, 'new_index': e.value};
        }).toList(),
      },
    );
  }

  Future<void> deleteAnimal(Animal animal) async {
    await _supabase
        .from('animals')
        .update({'deleted': true})
        .eq('a_id', animal.aid);
  }

  Future<void> deleteLab(Lab lab) async {
    await _supabase.from('labs').update({'deleted': true}).eq('l_id', lab.lid);
  }

  Future<void> deleteBuilding(Building building) async {
    await _supabase
        .from('buildings')
        .update({'deleted': true})
        .eq('b_id', building.bid);
  }

  Future<void> deleteFacility(Facility facility) async {
    await _supabase
        .from('facilities')
        .update({'deleted': true})
        .eq('f_id', facility.fid);
  }

  Future<void> deleteRoom(int rid) async {
    await _supabase.from('rooms').update({'deleted': true}).eq('r_id', rid);
  }

  Future<void> deleteTaskList(TaskList taskList) async {
    await _supabase
        .from('task_lists')
        .update({'deleted': true})
        .eq('tl_id', taskList.tlid);
  }

  Future<void> undeleteAnimal(String animalName) async {
    await _supabase
        .from('animals')
        .update({'deleted': false})
        .eq('name', animalName);
  }

  Future<void> undeleteLab(String labName) async {
    await _supabase.from('labs').update({'deleted': false}).eq('name', labName);
  }

  Future<void> undeleteBuilding(String buildingName) async {
    await _supabase
        .from('buildings')
        .update({'deleted': false})
        .eq('name', buildingName);
  }

  Future<void> undeleteFacility(String facilityName) async {
    await _supabase
        .from('facilities')
        .update({'deleted': false})
        .eq('name', facilityName);
  }

  Future<void> undeleteRoom(String roomName) async {
    await _supabase
        .from('rooms')
        .update({'deleted': false})
        .eq('name', roomName);
  }

  Future<void> undeleteTaskList(TaskList taskList) async {
    var tidToIndex = {
      for (int i = 0; i < taskList.tasks.length; i++) taskList.tasks[i].tid: i,
    };
    await _supabase.rpc(
      'insert_task_list',
      params: {
        'name_in': taskList.name,
        'frequency_in': taskList.frequency.toDbString,
        'task_list_task_membership_rows': tidToIndex.entries.map((e) {
          return {'t_id': e.key, 'index': e.value};
        }).toList(),
      },
    );
  }
}
