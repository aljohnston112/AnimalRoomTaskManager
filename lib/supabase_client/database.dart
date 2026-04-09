import 'package:supabase_flutter/supabase_flutter.dart';

class Database {
  final Supabase _supabase;

  Database._(this._supabase);

  static Future<Database> create() async {
    final connection = await Supabase.initialize(
      url: 'https://rlbbezekxurjffutovsz.supabase.co',
      anonKey: 'sb_publishable_tPiZgEloifhv8Af6sG_m1w_-mEQ1RnT',
    );
    return Database._(connection);
  }

  void subscribeToRoomChecks(void Function(PostgresChangePayload) callback) {
    _supabase.client
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
    _supabase.client
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
    // database._supabase.client.from("room_check_slots").insert({'date_time': DateTime(2026, 4, 8).toIso8601String(), 'r_id': 1, 'state': 'not_started', 'u_id': null,})
    return _supabase.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<List<PostgrestMap>> getRoomCheckSlots() async {
    final data = await _supabase.client.from('room_check_slots').select();
    return data.toList();
  }
}
