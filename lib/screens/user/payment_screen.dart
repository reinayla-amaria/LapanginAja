import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/court_model.dart';
import '../../providers/notification_provider.dart';
import 'main_nav_screen.dart';
import 'booking_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final Court court;
  final String date;
  final String time;
  final double totalPrice;
  final String snapToken;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.court,
    required this.date,
    required this.time,
    required this.totalPrice,
    required this.snapToken,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isProcessingNotif = false; // Cegah double trigger

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;
            debugPrint("Navigating to: $url");

            if (url.contains('lapanginaja.web.id/finish') ||
                url.contains('example.com') ||
                url.contains('finish')) {
              _handlePaymentSuccess(); // Ganti jadi function baru
              return NavigationDecision.prevent;
            }
            if (url.contains('lapanginaja.web.id/error') ||
                url.contains('error')) {
              _showResultDialog('error');
              return NavigationDecision.prevent;
            }
            if (url.contains('lapanginaja.web.id/pending') ||
                url.contains('pending')) {
              _showResultDialog('pending');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          'https://app.sandbox.midtrans.com/snap/v2/vtweb/${widget.snapToken}',
        ),
      );
  }

  // -------------------------------------------------------
  // FETCH detail booking dari API, lalu trigger notifikasi
  // -------------------------------------------------------
  Future<void> _handlePaymentSuccess() async {
    if (_isProcessingNotif) return;
    _isProcessingNotif = true;

    await Future.delayed(const Duration(seconds: 3));

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse(
          'https://lapanginaja.web.id/api/booking/${widget.bookingId}/detail',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("BODY: ${response.body}");
      if (response.statusCode == 200) {
        debugPrint(response.body);

        final json = jsonDecode(response.body);
        final data = json['data'];

        final booking = data['booking'];
        final lapangan = data['lapangan'];
        final user = data['user'];
        final payment = data['payment'];
        debugPrint(payment.toString());
        debugPrint(user.toString());

        // Trigger notifikasi
        if (mounted) {
          await Provider.of<NotificationProvider>(
            context,
            listen: false,
          ).addBookingNotification(
            bookingId: booking['id'].toString(),
            namaLapangan: lapangan['nama_lapangan'],
            lokasi: lapangan['lokasi'],
            tanggalMain: booking['tanggal_main'],
            jamMulai: booking['jam_mulai'],
            jamSelesai: booking['jam_selesai'],
            totalHarga: booking['total_harga'].toString(),
            userName: user?['name']?.toString() ?? '-',
            metodePembayaran:
                payment?['metode_pembayaran']?.toString() ?? 'Midtrans',
            transactionId: payment?['transaction_id']?.toString() ?? '-',
          );
        }
      } else {
        // Kalau API gagal, tetap trigger notifikasi dengan data yang ada
        debugPrint(
          'Fetch detail gagal: ${response.statusCode}, pakai data lokal',
        );
        _triggerNotifFromLocalData();
      }
    } catch (e) {
      debugPrint('Error fetch detail booking: $e');
      _triggerNotifFromLocalData();
    }

    // Navigasi ke success screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BookingSuccessScreen(
            court: widget.court,
            date: widget.date,
            time: widget.time,
            totalPrice: widget.totalPrice,
          ),
        ),
      );
    }
  }

  // Fallback: pakai data dari widget kalau API gagal
  void _triggerNotifFromLocalData() {
    if (!mounted) return;
    Provider.of<NotificationProvider>(
      context,
      listen: false,
    ).addBookingNotification(
      bookingId: widget.bookingId,
      namaLapangan: widget.court.name,
      lokasi: widget.court.location,
      tanggalMain: widget.date,
      jamMulai: widget.time.split(' - ')[0],
      jamSelesai: widget.time.split(' - ').length > 1
          ? widget.time.split(' - ')[1]
          : widget.time,
      totalHarga: widget.totalPrice.toStringAsFixed(0),
      userName: '-',
      metodePembayaran: 'Midtrans',
      transactionId: '-',
    );
  }

  void _showResultDialog(String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time,
                color: Colors.orange,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Pembayaran Pending",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Pembayaran sedang diproses.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF093FB4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const MainNavScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text("Kembali ke Home"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF093FB4),
        foregroundColor: Colors.white,
        title: const Text("Pembayaran LapanginAja"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading || _isProcessingNotif)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
