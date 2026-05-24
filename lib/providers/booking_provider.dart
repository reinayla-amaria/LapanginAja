import 'package:flutter/material.dart';
import '../models/court_model.dart';
import '../models/booking_models.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = "https://lapanginaja.web.id/api";

class BookingProvider with ChangeNotifier {
  List<Court> _courts = [];
  List<Court> get courts => _courts;

  List<Booking> _bookings = [];
  List<Booking> get bookings => _bookings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  String _lastSnapToken = '';
  String get lastSnapToken => _lastSnapToken;

  // 1. FETCH DATA LAPANGAN
  Future<void> fetchCourts() async {
    _isLoading = true;
    _errorMessage = '';
    _courts = [];
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/lapangan'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        final List<dynamic> data = result['data'];
        _courts = data.map((json) => Court.fromJson(json)).toList();
      } else {
        _errorMessage = "Server error: ${response.statusCode}";
      }
    } catch (e) {
      _errorMessage = "Gagal mengambil data: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. FETCH BOOKINGS
  Future<void> fetchBookings(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      debugPrint("TOKEN: $token");

      final response = await http.get(
        Uri.parse('$baseUrl/my-bookings'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List<dynamic> data = result['data'];
        _bookings = data.map((json) => Booking.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Error fetchBookings: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. CREATE BOOKING
  Future<bool> createBooking({
    required String userId,
    required String courtId,
    required DateTime date,
    required String time,
    required int duration,
    required double pricePerHour,
  }) async {
    if (userId == "null" || userId.isEmpty) {
      debugPrint("Error: User ID kosong!");
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      String jamMulai = time.split(' - ')[0].trim();
      String jamSelesai = time.split(' - ')[1].trim();
      double totalHarga = pricePerHour * duration;
      String formattedDate =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      final response = await http.post(
        Uri.parse('$baseUrl/checkout'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'lapangan_id': courtId,
          'tanggal_main': formattedDate,
          'jam_mulai': jamMulai,
          'jam_selesai': jamSelesai,
          'total_harga': totalHarga,
        }),
      );

      debugPrint(
        "Checkout response: ${response.statusCode} - ${response.body}",
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _lastSnapToken = result['snap_token'] ?? '';
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error createBooking: $e");
      return false;
    }
  }
}
