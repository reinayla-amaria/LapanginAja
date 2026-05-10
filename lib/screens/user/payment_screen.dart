import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/court_model.dart';
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
              _showResultDialog('finish');
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

  void _showResultDialog(String url) {
    bool isSuccess = url.contains('finish');

    if (isSuccess) {
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
      return;
    }

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
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
