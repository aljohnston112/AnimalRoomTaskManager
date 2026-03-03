import 'package:postgres/postgres.dart';

class Database {
  final Connection _connection;

  Database._(this._connection);

  static Future<Database> create() async {
    final connection = await Connection.open(
      Endpoint(
        host: 'localhost',
        database: 'tmdb',
        username: 'main',
        password: "maintmdb",
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );

    return Database._(connection);
  }
}
