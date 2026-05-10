import 'package:http/http.dart' as http;
import 'dart:convert';

class GoogleUserService {
  // 1. Tambahkan https:// dan sesuaikan jika ada prefix /api
  final String baseUrl = "https://lapanginaja.web.id/api";

  Future<void> registerGoogleUser({
    required String name,
    required String email,
    required String googleId,
    String? photoUrl,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/register_google');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept':
                  'application/json', // Tambahkan ini agar Laravel kirim error dalam bentuk JSON
            },
            body: jsonEncode({
              'name': name,
              'email': email,
              'google_id': googleId,
              'photo_url': photoUrl ?? "",
            }),
          )
          .timeout(
            const Duration(seconds: 10),
          ); // Tambahkan timeout biar nggak nunggu selamanya

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ User tersimpan di DB");
      } else {
        // Ini akan membantu kamu melihat error dari Laravel (misal: validation error)
        print("❌ Gagal simpan user. Status: ${response.statusCode}");
        print("Pesan Server: ${response.body}");
      }
    } catch (e) {
      // Menangkap error koneksi/internet
      print("        Error Koneksi: $e");
    }
  }
}
