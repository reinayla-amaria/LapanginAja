import 'package:mysql1/mysql1.dart';

class DBService {
  static Future<MySqlConnection> getConnection() async {
    return await MySqlConnection.connect(
      ConnectionSettings(
        host: '127.0.0.1', // <--- Pastikan ini sesuai hasil ipconfig terbaru
        port: 3306,
        user: 'root',
        password: ' ', // Kosongkan sesuai settingan di HeidiSQL kamu
        db: 'db_lapangan',
        timeout: const Duration(seconds: 10),
      ),
    );
  }
}
