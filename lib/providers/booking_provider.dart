import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import '../models/court_model.dart';
import '../models/booking_models.dart';
import '../services/db_connection.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = "https://lapanginaja.web.id/api";
String _lastSnapToken = '';
String get lastSnapToken => _lastSnapToken;

class BookingProvider with ChangeNotifier {
  List<Court> _courts = [];
  List<Court> get courts => _courts;

  List<Booking> _bookings = [];
  List<Booking> get bookings => _bookings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  String _lastSnapToken = ''; // ← TAMBAH INI
  String get lastSnapToken => _lastSnapToken; // ← TAMBAH INI

  // 1. FETCH DATA GEDUNG (MITRA) - VERSI FIX
  Future<void> fetchCourts() async {
    _isLoading = true;
    _errorMessage = '';
    _courts = [];
    notifyListeners();

    try {
      debugPrint("--- MEMULAI FETCH COURTS VIA API ---");

      final response = await http.get(
        Uri.parse('$baseUrl/lapangan'),
        headers: {'Accept': 'application/json'},
      );

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        final List<dynamic> data = result['data'];

        _courts = data.map((json) => Court.fromJson(json)).toList();
        debugPrint("Jumlah courts: ${_courts.length}");
      } else {
        _errorMessage = "Server error: ${response.statusCode}";
        debugPrint("Server Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      _errorMessage = "Gagal mengambil data: $e";
      debugPrint("!!! ERROR FETCH COURTS: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. FETCH BOOKINGS (Biarkan tetap seperti ini, sudah benar)
  Future<void> fetchBookings(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final conn = await DBService.getConnection();
      Results results = await conn.query(
        "SELECT b.*, l.nama_lapangan FROM bookings b "
        "JOIN lapangans l ON b.lapangan_id = l.id "
        "WHERE b.user_id = ? ORDER BY b.tanggal_main DESC",
        [userId],
      );

      _bookings = results.map((row) {
        final data = row.asMap();
        DateTime dt = data['tanggal_main'] is DateTime
            ? data['tanggal_main']
            : DateTime.now();
        String formattedDate =
            "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

        return Booking(
          id: data['id'].toString(),
          courtId: data['lapangan_id'].toString(),
          userId: data['user_id'].toString(),
          courtName: data['nama_lapangan']?.toString() ?? 'Lapangan',
          date: formattedDate,
          time: data['jam_mulai'].toString(),
          totalPrice: double.tryParse(data['total_harga'].toString()) ?? 0.0,
          status: data['status'].toString(),
        );
      }).toList();
      await conn.close();
    } catch (e) {
      debugPrint("Error Fetch Bookings: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // Di dalam class BookingProvider

  List<Court> _subCourts = [];
  List<Court> get subCourts =>
      _subCourts; // Untuk menampung daftar lapangan milik 1 mitra

  Future<void> fetchCourtsByMitra(String mitraId) async {
    _isLoading = true;
    _subCourts = []; // Bersihkan data lama agar tidak tertukar
    notifyListeners();

    try {
      // Kita panggil API yang sama, karena Laravel sudah mengirim data lapangan beserta mitra_id-nya
      final response = await http.get(Uri.parse('$baseUrl/lapangan'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        final List<dynamic> allCourtsData = result['data'];

        // Filter di sisi Flutter: Hanya ambil lapangan yang mitra_id-nya cocok
        // Note: Pastikan di Laravel, API Lapangan kamu juga mengirim 'mitra_id'
        _subCourts = allCourtsData
            .where((json) => json['mitra_id'].toString() == mitraId)
            .map((json) => Court.fromJson(json))
            .toList();
      } else {
        debugPrint("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error Fetch SubCourts via API: $e");
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
      // Hitung jam selesai
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
        },
        body: jsonEncode({
          'user_id': userId,
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
        // Simpan snap_token untuk payment
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
