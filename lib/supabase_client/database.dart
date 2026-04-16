import 'package:animal_room_task_manager/room_check/room_check_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../user_management/user_repository.dart' as ur;

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

  Future<bool> login({required String email, required String password}) async {
    try {
      // database._supabase.from("room_check_slots").insert({'date_time': DateTime(2026, 4, 8).toIso8601String(), 'r_id': 1, 'state': 'not_started', 'u_id': null,})
      await _supabase.auth.signInWithPassword(email: email, password: password);
      return true;
    } on AuthApiException {
      return false;
    }
  }

  Future<List<PostgrestMap>> getRoomCheckSlots() async {
    final today = DateTime.now();
    final startOfToday = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();
    final data = await _supabase
        .from('room_check_slots_view')
        .select('''
    *
  ''')
        .gte('date_time', startOfToday);
    return data.toList();
  }

  void signUp({required String email, required String password}) async {
    await _supabase.auth.signUp(email: email, password: password);
  }

  void subscribeToAuth(void Function(AuthState) onAuthChange) {
    _supabase.auth.onAuthStateChange.listen((data) {
      onAuthChange(data);
    });
  }

  Future<ur.UserGroup> getUserGroup(String? email) async {
    final data = await _supabase.from('email_whitelist').select('''
    ug_id, email
  ''');
    final whereEmailMatches = data.where((d) => d["email"] == email);
    if (whereEmailMatches.isEmpty) {
      throw Exception("User is not white listed");
    }
    switch (whereEmailMatches.first['ug_id']) {
      case 0:
        return ur.UserGroup.admin;
      case 1:
        return ur.UserGroup.principalInvestigatorOrChiefOfStaff;
      case 2:
        return ur.UserGroup.roomChecker;
    }
    throw Exception("Invalid user group");
  }

  Future<void> assignUserToRoomCheck(
    RoomCheckSlot roomCheckSlot,
    String userEmail,
  ) async {
    // TODO get id from ram
    final userResponse = await _supabase
        .from('users')
        .select('u_id')
        .eq('name', userEmail)
        .maybeSingle();
    if (userResponse != null) {
      final int userId = userResponse['u_id'];
      final rcid = roomCheckSlot.rcid;
      if (rcid != null) {
        _supabase
            .from(roomCheckTableName)
            .update({'u_id': userId})
            .eq('rc_id', rcid);
      } else {
        // TODO insert
        // _supabase.from(roomCheckTableName).insert({
        //   'date_time',
        //   roomCheckSlot.date.toSupabaseString(),
        //   'r_id': roomCheckSlot.
        // });
      }
    }
  }
}
