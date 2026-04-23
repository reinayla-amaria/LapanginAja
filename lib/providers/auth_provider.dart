import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _token;
  String? _userName;
  String? _userEmail; // Tambahkan ini agar email bisa dipanggil di dashboard

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get userName => _userName;
  String? get userEmail => _userEmail; // Getter untuk email

  final String baseUrl = "http://157.10.253.206:8080/api";

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // --- FUNGSI BARU: CEK STATUS SAAT APP DIBUKA ---
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('is_login') ?? false;
    if (_isLoggedIn) {
      _token = prefs.getString('token');
      _userName = prefs.getString('user_name');
      _userEmail = prefs.getString('user_email');
    }
    notifyListeners();
  }

  // Register
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
        }),
      );

      final result = jsonDecode(response.body);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'status': 'error', 'message': 'Koneksi gagal: $e'};
    }
  }

  // Login Manual
  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      );

      final result = jsonDecode(response.body);

      if (result['status'] == 'success' || result['token'] != null) {
        _token = result['token'];
        // Mengambil data user secara dinamis dari response API
        _userName = result['user'] != null ? result['user']['name'] : 'User';
        _userEmail = result['user'] != null ? result['user']['email'] : email;
        _isLoggedIn = true;

        // Simpan ke memori HP
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_login', true);
        await prefs.setString('token', _token!);
        await prefs.setString('user_name', _userName!);
        await prefs.setString(
          'user_email',
          _userEmail!,
        ); // Simpan email dinamis
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'status': 'error', 'message': 'Koneksi gagal: $e'};
    }
  }

  // Google Login
  Future<Map<String, dynamic>> googleLogin({
    required String name,
    required String email,
    required String googleId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/google-login'),
        headers: _headers,
        body: jsonEncode({'name': name, 'email': email, 'google_id': googleId}),
      );
      final result = jsonDecode(response.body);

      if (result['status'] == 'success') {
        _token = result['token'];
        _userName = result['user']['name'];
        _userEmail = result['user']['email'];
        _isLoggedIn = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_login', true);
        await prefs.setString('token', _token!);
        await prefs.setString('user_name', _userName!);
        await prefs.setString('user_email', _userEmail!);
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'status': 'error', 'message': 'Koneksi gagal: $e'};
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus semua data di HP
    _isLoggedIn = false;
    _token = null;
    _userName = null;
    _userEmail = null;
    notifyListeners();
  }
}
