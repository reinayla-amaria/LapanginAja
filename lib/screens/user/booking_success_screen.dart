import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/court_model.dart';
import 'main_nav_screen.dart';

class BookingSuccessScreen extends StatefulWidget {
  final Court court;
  final String date;
  final String time;
  final double totalPrice;

  const BookingSuccessScreen({
    super.key,
    required this.court,
    required this.date,
    required this.time,
    required this.totalPrice,
  });

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen> {
  bool _showDetail = false;

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF093FB4);
    const accentGreen = Color(0xFF00C853);

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.only(
              top: 70,
              left: 24,
              right: 24,
              bottom: 16,
            ),
            decoration: const BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 12),
                Image.asset('assets/logo_white.png', height: 40),
                const Spacer(),
              ],
            ),
          ),

          // KONTEN
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _showDetail
                  ? _buildDetailPesanan(
                      primaryBlue,
                      accentGreen,
                      currencyFormatter,
                    )
                  : _buildSuccessPage(accentGreen),
            ),
          ),

          // BOTTOM NAV
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.home, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const MainNavScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.sports_tennis, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.person, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessPage(Color accentGreen) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          "Yeay! Booking Kamu Berhasil 🎉",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),

        // Gambar
        Container(
          height: 250,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Image.asset('assets/sukses_screen.png', fit: BoxFit.contain),
        ),

        const SizedBox(height: 24),

        Center(
          child: SizedBox(
            width: 220,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() => _showDetail = true);
              },
              child: const Text(
                "Lihat Detail Pesanan",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailPesanan(
    Color primaryBlue,
    Color accentGreen,
    NumberFormat currencyFormatter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text(
          "Detail Pesanan",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildDetailRow("Nama Venue", widget.court.name),
              const Divider(height: 24),
              _buildDetailRow("Lapangan", widget.court.courtName),
              const Divider(height: 24),
              _buildDetailRow("Tanggal", widget.date),
              const Divider(height: 24),
              _buildDetailRow("Waktu", widget.time),
              const Divider(height: 24),
              _buildDetailRow("Durasi", "1 Jam"),
              const Divider(height: 24),
              _buildDetailRow(
                "Total Bayar",
                currencyFormatter.format(widget.totalPrice),
                isBold: true,
                color: primaryBlue,
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MainNavScreen()),
                (route) => false,
              );
            },
            child: const Text(
              "Kembali Ke Beranda",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
