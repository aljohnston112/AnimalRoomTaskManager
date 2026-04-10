import 'package:supabase_flutter/supabase_flutter.dart';

import '../user_management/user_repository.dart' as ur;

class Database {
  final SupabaseClient _supabase;

  Database._(this._supabase);

  static Future<Database> create() async {
    final connection = await Supabase.initialize(
      url: 'https://rlbbezekxurjffutovsz.supabase.co',
      anonKey: 'sb_publishable_tPiZgEloifhv8Af6sG_m1w_-mEQ1RnT',
    );
    return Database._(connection.client);
  }

  void subscribeToRoomChecks(void Function(PostgresChangePayload) callback) {
    _supabase
        .channel("room_check_slots")
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'room_check_slots',
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

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    // database._supabase.from("room_check_slots").insert({'date_time': DateTime(2026, 4, 8).toIso8601String(), 'r_id': 1, 'state': 'not_started', 'u_id': null,})
    return _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<List<PostgrestMap>> getRoomCheckSlots() async {
    final today = DateTime.now();
    final startOfToday = DateTime(
      today.year,
      today.month,
      today.day,
    ).toIso8601String();
    final data = await _supabase
        .from('room_check_slots')
        .select('''
    *,
    rooms (
      name
    )
  ''')
        .gte('date_time', startOfToday);
    return data.toList();
  }

  Future<ur.User> signUp({
    required String email,
    required String password,
  }) async {
    final AuthResponse res = await _supabase.auth.signUp(
      email: 'example@email.com',
      password: 'example-password',
    );
    final Session? session = res.session;
    final User? user = res.user;
    // TODO add user to user table
    // TODO get group from whitelist table
    return ur.User(email: email, group: ur.UserGroup.roomChecker);
  }
}
