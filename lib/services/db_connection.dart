import 'package:mysql1/mysql1.dart';

class DBService {
  static Future<MySqlConnection> getConnection() async {
    return await MySqlConnection.connect(
      ConnectionSettings(
        host: '127.0.0.1', // ganti dengan IP / hostname MySQL
        port: 3306,
        user: 'root', // username MySQL
        password: ' ', // password MySQL
        db: 'db_lapangan', // nama database
      ),
    );
  }
}
