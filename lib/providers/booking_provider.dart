import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import '../models/court_model.dart';
import '../models/booking_models.dart';
import '../services/db_connection.dart';

class BookingProvider with ChangeNotifier {
  List<Court> _courts = [];
  List<Court> get courts => _courts;

  List<Booking> _bookings = [];
  List<Booking> get bookings => _bookings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // 1. FETCH DATA GEDUNG (MITRA) - VERSI FIX
  Future<void> fetchCourts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final conn = await DBService.getConnection();

      // Kita panggil kolomnya tanpa alias yang aneh-aneh
      // Index: 0=u.id, 1=u.name, 2=l.lokasi, 3=harga, 4=foto
      Results results = await conn.query("""
      SELECT 
        u.id, 
        u.name, 
        l.lokasi, 
        MIN(l.harga_per_jam), 
        l.foto 
      FROM lapangans l
      JOIN users u ON l.mitra_id = u.id
      GROUP BY u.id, u.name, l.lokasi, l.foto
      ORDER BY u.name ASC
    """);

      _courts = results.map((row) {
        // DEBUG: Ini akan memunculkan isi asli dari database di console log kamu
        // Cek di Debug Console, apakah nama-nama itu muncul di sana?
        print("ISI ROW ASLI: ${row.toList()}");

        return Court(
          // Kita ambil data berdasarkan INDEX kolom (0, 1, 2, dst)
          id: row[0].toString(),
          name:
              row[1]?.toString() ??
              'Nama Tidak Terdeteksi', // row[1] adalah u.name
          location:
              row[2]?.toString() ??
              'Lokasi tidak tersedia', // row[2] adalah l.lokasi
          pricePerHour:
              double.tryParse(row[3].toString()) ?? 0.0, // row[3] adalah harga
          imageUrl: (row[4] != null && row[4].toString() != "NULL")
              ? row[4].toString()
              : 'https://via.placeholder.com/150',
          facilities: ["Parkir", "Toilet"],
          description: 'Pusat olahraga berkualitas.',
        );
      }).toList();

      await conn.close();
    } catch (e) {
      debugPrint("Error Fetch: $e");
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

  // 3. CREATE BOOKING
  Future<bool> createBooking({
    required String userId,
    required String courtId,
    required DateTime date,
    required String time,
    required int duration,
    required double pricePerHour,
  }) async {
    try {
      final conn = await DBService.getConnection();
      double totalPrice = pricePerHour * duration;
      String formattedDate =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

      var result = await conn.query(
        'INSERT INTO bookings (user_id, lapangan_id, tanggal_main, jam_mulai, total_harga, status) VALUES (?, ?, ?, ?, ?, ?)',
        [userId, courtId, formattedDate, time, totalPrice, 'pending'],
      );

      await conn.close();
      return (result.affectedRows ?? 0) > 0;
    } catch (e) {
      return false;
    }
  }
}
