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
}
