import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiServices {
  // Tambahkan 'api' di sini dan hapus slash di ujung biar rapi
  static const String baseUrl = "http://157.10.253.206:8080/api";

  // Fungsi Registrasi
  Future<http.Response> register(
    String name,
    String email,
    String password,
  ) async {
    // Tambahkan slash di awal endpoint
    final url = Uri.parse('$baseUrl/register');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation':
              password, // Biasanya Laravel minta konfirmasi password
        }),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Fungsi Login
  Future<http.Response> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login'); // Pakai baseUrl yang baru
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );
  }
}
