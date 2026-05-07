import 'package:mysql1/mysql1.dart';

class DBService {
  static Future<MySqlConnection> getConnection() async {
    return await MySqlConnection.connect(
      ConnectionSettings(
        host: 'byiqomiqoan10dwxncid-mysql.services.clever-cloud.com', // PAKAI 10
        port: 3306,
        user: 'uwpggsleh944hpyo',
        password: 'ayniqLbgmRsG2kDeO14t',
        db: 'byiqomiqoan10dwxncid', // PAKAI 10
        timeout: const Duration(seconds: 30),
      ),
    );
  }
}