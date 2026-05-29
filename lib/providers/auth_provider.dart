import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _userId;
  String? _token;
  String? _userName;
  String? _userEmail;
  String? _username;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get username => _username;
  Map<String, dynamic>? get user => _user;

  final String baseUrl = "https://lapanginaja.web.id/api";

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('is_login') ?? false;
    if (_isLoggedIn) {
      _token = prefs.getString('token');
      _userName = prefs.getString('user_name');
      _userEmail = prefs.getString('user_email');
      _userId = prefs.getString('user_id');
      _username = prefs.getString('username');
    }
    notifyListeners();
    return _isLoggedIn;
  }

  // -------------------------------------------------------
  // REGISTER — sekarang kirim username juga
  // -------------------------------------------------------
  Future<Map<String, dynamic>> register({
    required String name,
    required String username,
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
          'username': username,
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

  // -------------------------------------------------------
  // LOGIN
  // -------------------------------------------------------
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
      if (response.statusCode == 200) {
        _token = result['token'];
        _userName = result['user']['name'];
        _userEmail = result['user']['email'];
        _userId = result['user']['id'].toString();
        _username = result['user']['username'];
        _isLoggedIn = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_login', true);
        await prefs.setString('token', _token!);
        await prefs.setString('user_name', _userName!);
        await prefs.setString('user_email', _userEmail!);
        await prefs.setString('user_id', _userId!);
        if (_username != null) {
          await prefs.setString('username', _username!);
        }
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

  // -------------------------------------------------------
  // GOOGLE LOGIN
  // -------------------------------------------------------
  Future<Map<String, dynamic>> googleLogin({
    required String name,
    required String email,
    required String googleId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register_google"),
        headers: _headers,
        body: jsonEncode({'name': name, 'email': email, 'google_id': googleId}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _token = data['access_token'];
        _user = data['user'];
        _userName = data['user']['name'];
        _userEmail = data['user']['email'];
        _userId = data['user']['id'].toString();
        _username = data['user']['username'];
        _isLoggedIn = true;

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_login', true);
        await prefs.setString('token', _token!);
        await prefs.setString('user_name', _userName!);
        await prefs.setString('user_email', _userEmail!);
        await prefs.setString('user_id', _userId!);
        if (_username != null) {
          await prefs.setString('username', _username!);
        }

        _isLoading = false;
        notifyListeners();
        return {'status': 'success', 'message': data['message']};
      } else {
        _isLoading = false;
        notifyListeners();
        return {'status': 'error', 'message': data['message'] ?? 'Gagal login'};
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'status': 'error', 'message': 'Terjadi kesalahan koneksi'};
    }
  }

  // -------------------------------------------------------
  // LOGOUT
  // -------------------------------------------------------
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _isLoggedIn = false;
    _token = null;
    _userName = null;
    _userEmail = null;
    _userId = null;
    _username = null;
    _user = null;
    notifyListeners();
  }
}
