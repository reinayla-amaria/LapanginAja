import 'package:http/http.dart' as http;
import 'dart:convert';

class GoogleUserService {
  final String baseUrl = "https://your-backend.com/api"; // Ganti sesuai backend

  Future<void> registerGoogleUser({
    required String name,
    required String email,
    required String googleId,
    String? photoUrl,
  }) async {
    final url = Uri.parse('$baseUrl/register_google');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'google_id': googleId,
        'photo_url': photoUrl ?? "",
      }),
    );

    if (response.statusCode == 200) {
      print("User tersimpan di DB");
    } else {
      print("Gagal simpan user: ${response.body}");
    }
  }
}