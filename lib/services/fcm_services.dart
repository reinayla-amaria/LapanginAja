import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/notification_provider.dart';

// -------------------------------------------------------
// Background message handler — HARUS di luar class / top-level function
// -------------------------------------------------------
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background FCM: ${message.messageId}');
  // Simpan ke SharedPreferences supaya bisa dibaca saat app dibuka
  await _saveNotifToPrefs(message);
}

Future<void> _saveNotifToPrefs(RemoteMessage message) async {
  final prefs = await SharedPreferences.getInstance();
  final data = message.data;
  if (data.isEmpty) return;

  final existing = prefs.getString('pending_fcm_notif');
  final List list = existing != null ? jsonDecode(existing) : [];
  list.add(data);
  await prefs.setString('pending_fcm_notif', jsonEncode(list));
}

// -------------------------------------------------------
// FCM Service Class
// -------------------------------------------------------
class FcmService {
  static final _messaging = FirebaseMessaging.instance;

  // 1. Inisialisasi — dipanggil di main()
  static Future<void> initialize(BuildContext context) async {
    // Minta izin notifikasi
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('FCM Permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Ambil & kirim token ke Laravel
      await _sendTokenToServer();

      // Listener token refresh
      _messaging.onTokenRefresh.listen((_) => _sendTokenToServer());

      // Foreground handler
      FirebaseMessaging.onMessage.listen((message) {
        _handleForegroundMessage(context, message);
      });

      // App dibuka dari notif (background → foreground)
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleMessageOpenedApp(context, message);
      });

      // Cek notif yang masuk saat app terminated
      await _checkPendingNotifications(context);
    }
  }

  // 2. Kirim FCM token ke Laravel
  static Future<void> _sendTokenToServer() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      debugPrint('FCM Token: $token');

      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token') ?? '';

      await http.post(
        Uri.parse('https://lapanginaja.web.id/api/fcm-token'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fcm_token': token}),
      );
    } catch (e) {
      debugPrint('Gagal kirim FCM token: $e');
    }
  }

  // 3. Handle notif saat app FOREGROUND (terbuka)
  static void _handleForegroundMessage(
    BuildContext context,
    RemoteMessage message,
  ) {
    final data = message.data;
    if (data['type'] != 'booking_success') return;
    debugPrint("DATA FCM DITERIMA: $data");

    if (data['type'] != 'booking_success') return;
    // Tambah ke NotificationProvider
    final notifProv = Provider.of<NotificationProvider>(context, listen: false);
    notifProv.addBookingNotification(
      bookingId: data['booking_id'] ?? '',
      namaLapangan: data['nama_lapangan'] ?? '',
      lokasi: data['lokasi'] ?? '',
      tanggalMain: data['tanggal_main'] ?? '',
      jamMulai: data['jam_mulai'] ?? '',
      jamSelesai: data['jam_selesai'] ?? '',
      totalHarga: data['total_harga'] ?? '',
      userName: data['user_name'] ?? '',
      metodePembayaran: data['metode_pembayaran'] ?? '',
      transactionId: data['transaction_id'] ?? '',
    );

    // Tampilkan snackbar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Booking ${data['nama_lapangan']} berhasil!'),
          backgroundColor: const Color(0xFF093FB4),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // 4. Handle saat user tap notif dari background
  static void _handleMessageOpenedApp(
    BuildContext context,
    RemoteMessage message,
  ) {
    final data = message.data;
    if (data['type'] != 'booking_success') return;

    final notifProv = Provider.of<NotificationProvider>(context, listen: false);
    notifProv.addBookingNotification(
      bookingId: data['booking_id'] ?? '',
      namaLapangan: data['nama_lapangan'] ?? '',
      lokasi: data['lokasi'] ?? '',
      tanggalMain: data['tanggal_main'] ?? '',
      jamMulai: data['jam_mulai'] ?? '',
      jamSelesai: data['jam_selesai'] ?? '',
      totalHarga: data['total_harga'] ?? '',
      userName: data['user_name'] ?? '',
      metodePembayaran: data['metode_pembayaran'] ?? '',
      transactionId: data['transaction_id'] ?? '',
    );
  }

  // 5. Cek notif yang masuk saat app terminated
  static Future<void> _checkPendingNotifications(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getString('pending_fcm_notif');
    if (pending == null) return;

    final List list = jsonDecode(pending);
    final notifProv = Provider.of<NotificationProvider>(context, listen: false);

    for (final data in list) {
      if (data['type'] == 'booking_success') {
        await notifProv.addBookingNotification(
          bookingId: data['booking_id'] ?? '',
          namaLapangan: data['nama_lapangan'] ?? '',
          lokasi: data['lokasi'] ?? '',
          tanggalMain: data['tanggal_main'] ?? '',
          jamMulai: data['jam_mulai'] ?? '',
          jamSelesai: data['jam_selesai'] ?? '',
          totalHarga: data['total_harga'] ?? '',
          userName: data['user_name'] ?? '',
          metodePembayaran: data['metode_pembayaran'] ?? '',
          transactionId: data['transaction_id'] ?? '',
        );
      }
    }

    // Hapus pending setelah diproses
    await prefs.remove('pending_fcm_notif');
  }
}
