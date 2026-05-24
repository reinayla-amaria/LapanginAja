import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiServices {
  static const String baseUrl =
      "https://backend-lapanginaja-production.up.railway.app/api";

  // 1. Fungsi Registrasi (SUDAH OKE)
  Future<http.Response> register(
    String name,
    String email,
    String password,
  ) async {
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
          'password_confirmation': password,
        }),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // 2. Fungsi Login Manual (SUDAH OKE)
  Future<http.Response> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );
  }

  // 3. Fungsi Login Google (TAMBAHKAN INI)
  Future<http.Response> googleLogin(
    String name,
    String email,
    String googleId,
  ) async {
    final url = Uri.parse(
      '$baseUrl/google-login',
    ); // Sesuaikan endpoint di routes/api.php kamu
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'name': name, 'email': email, 'google_id': googleId}),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
