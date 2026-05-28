import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications => _notifications;

  // Badge count untuk HomeScreen
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // -------------------------------------------------------
  // LOAD dari SharedPreferences
  // -------------------------------------------------------
  Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('notifications');
    if (data != null) {
      final List decoded = jsonDecode(data);
      _notifications = decoded
          .map((e) => NotificationModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    }
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_notifications.map((n) => n.toMap()).toList());
    await prefs.setString('notifications', encoded);
  }

  // -------------------------------------------------------
  // TAMBAH notifikasi — dipanggil setelah payments.status = 'sukses'
  // Parameter disesuaikan dengan JOIN:
  // bookings + lapangans + users + payments
  // -------------------------------------------------------
  Future<void> addBookingNotification({
    required String bookingId,
    required String namaLapangan, // lapangans.nama_lapangan
    required String lokasi, // lapangans.lokasi
    required String tanggalMain, // bookings.tanggal_main
    required String jamMulai, // bookings.jam_mulai
    required String jamSelesai, // bookings.jam_selesai
    required String totalHarga, // bookings.total_harga
    required String userName, // users.name
    required String metodePembayaran, // payments.metode_pembayaran
    required String transactionId, // payments.transaction_id
  }) async {
    final newNotif = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Pembayaran Berhasil! 🎉',
      message:
          'Booking $namaLapangan pada $tanggalMain pukul $jamMulai - $jamSelesai telah dikonfirmasi.',
      createdAt: DateTime.now(),
      isRead: false,
      bookingId: bookingId,
      namaLapangan: namaLapangan,
      lokasi: lokasi,
      tanggalMain: tanggalMain,
      jamMulai: jamMulai,
      jamSelesai: jamSelesai,
      totalHarga: totalHarga,
      userName: userName,
      metodePembayaran: metodePembayaran,
      transactionId: transactionId,
    );

    _notifications.insert(0, newNotif);
    await _saveNotifications();
    notifyListeners();
  }

  // -------------------------------------------------------
  // MARK AS READ
  // -------------------------------------------------------
  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (var notif in _notifications) {
      notif.isRead = true;
    }
    await _saveNotifications();
    notifyListeners();
  }

  // -------------------------------------------------------
  // HAPUS
  // -------------------------------------------------------
  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }
}
