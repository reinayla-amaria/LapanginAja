import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import '../models/court_model.dart';
import '../models/booking_models.dart';
import '../services/db_connection.dart';

class BookingProvider with ChangeNotifier {

  // --- DATA LAPANGAN ---
  List<Court> _courts = [];
  List<Court> get courts => _courts;

  // --- DATA BOOKING ---
  List<Booking> _bookings = [];
  List<Booking> get bookings => _bookings;

  // --- STATE ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // 1. FETCH DATA LAPANGAN
  Future<void> fetchCourts() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final conn = await DBService.getConnection();
      Results results = await conn.query(
        "SELECT id, nama_lapangan, harga_per_jam, foto, lokasi FROM lapangans ORDER BY nama_lapangan ASC",
      );

      _courts = results.map((row) {
        return Court(
          id: row['id'].toString(),
          name: row['nama_lapangan'] ?? '',
          location: row['lokasi'] ?? '',
          pricePerHour: (row['harga_per_jam'] as num).toDouble(),
          imageUrl: row['foto'] != null ? row['foto'].toString() : '',
          facilities: [],
          description: '',
        );
      }).toList();

      await conn.close();
    } catch (e) {
      _errorMessage = e.toString();
      _courts = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // 2. FETCH RIWAYAT BOOKING
  Future<void> fetchBookings(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final conn = await DBService.getConnection();
      Results results = await conn.query(
        "SELECT * FROM bookings WHERE user_id = ? ORDER BY created_at DESC",
        [userId],
      );

      _bookings = results.map((row) {
        return Booking.fromJson({
          'id': row['id'].toString(),
          'court_id': row['court_id'].toString(),
          'user_id': row['user_id'].toString(),
          'date': row['date'].toString(),
          'time': row['time'].toString(),
          'total_price': row['total_price'],
          'status': row['status'] ?? 'pending',
        });
      }).toList();

      await conn.close();
    } catch (e) {
      debugPrint("Error Fetch Bookings: $e");
      _bookings = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // 3. CREATE BOOKING
  Future<bool> createBooking(
    String courtId,
    DateTime date,
    String time,
    int duration,
    double pricePerHour,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      double totalPrice = pricePerHour * duration;
      String dateString = date.toIso8601String().split('T')[0];

      final conn = await DBService.getConnection();
      await conn.query(
        "INSERT INTO bookings (court_id, date, time, duration, total_price, status) VALUES (?, ?, ?, ?, ?, 'pending')",
        [courtId, dateString, time, duration, totalPrice],
      );
      await conn.close();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error Create Booking: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}