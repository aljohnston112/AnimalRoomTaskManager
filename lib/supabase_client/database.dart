import 'package:supabase_flutter/supabase_flutter.dart';
import '../user_management/user_repository.dart' as ur;

class Database {
  final SupabaseClient _supabase;

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

  void login({
    required String email,
    required String password,
  }) async {
    try {
      // database._supabase.from("room_check_slots").insert({'date_time': DateTime(2026, 4, 8).toIso8601String(), 'r_id': 1, 'state': 'not_started', 'u_id': null,})
      _supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthApiException {
      // TODO login failed
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

  void signUp({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  void subscribeToAuth(void Function(AuthState) onAuthChange) {
    _supabase.auth.onAuthStateChange.listen((data) {
      onAuthChange(data);
    });
  }

  Future<ur.UserGroup> getUserGroup(String? email) async {
    final data = await _supabase
        .from('email_whitelist')
        .select('''
    ug_id, email
  ''');
    final whereEmailMatches =
    data.where((d)=>d["email"] == email);
    if(whereEmailMatches.isEmpty){
      throw Exception("User is not white listed");
    }
    switch(whereEmailMatches.first['ug_id']){
      case 0: return ur.UserGroup.admin;
      case 1: return ur.UserGroup.principalInvestigatorOrChiefOfStaff;
      case 2: return ur.UserGroup.roomChecker;
    }
    throw Exception("Invalid user group");
  }
}
