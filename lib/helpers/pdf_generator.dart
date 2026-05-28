import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import '../models/notification_model.dart';

class PdfGenerator {
  static final _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String _formatRupiah(String value) {
    try {
      return _rupiahFormat.format(int.parse(value));
    } catch (_) {
      return 'Rp $value';
    }
  }

  /// Generate PDF bukti booking dan langsung buka
  static Future<void> generateAndOpenBookingPdf(
    BuildContext context,
    NotificationModel notif,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ---- HEADER ----
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#093FB4'),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BUKTI BOOKING LAPANGAN',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Booking ID: #${notif.bookingId}',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                        ),
                      ),
                      pw.Text(
                        'Transaction ID: ${notif.transactionId}',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // ---- STATUS SUKSES ----
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#E8F5E9'),
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(
                      color: PdfColor.fromHex('#4CAF50'),
                      width: 1,
                    ),
                  ),
                  child: pw.Text(
                    '✓  PEMBAYARAN SUKSES',
                    style: pw.TextStyle(
                      color: PdfColor.fromHex('#2E7D32'),
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),

                pw.SizedBox(height: 24),

                // ---- DETAIL LAPANGAN ----
                _sectionTitle('Detail Lapangan'),
                pw.SizedBox(height: 8),
                _buildRow('Nama Lapangan', notif.namaLapangan),
                _buildRow('Lokasi', notif.lokasi),
                _buildRow('Tanggal Main', notif.tanggalMain),
                _buildRow(
                  'Jam Main',
                  '${notif.jamMulai} - ${notif.jamSelesai}',
                ),

                pw.SizedBox(height: 20),

                // ---- DETAIL PENYEWA ----
                _sectionTitle('Detail Penyewa'),
                pw.SizedBox(height: 8),
                _buildRow('Nama Penyewa', notif.userName),

                pw.SizedBox(height: 20),

                // ---- DETAIL PEMBAYARAN ----
                _sectionTitle('Detail Pembayaran'),
                pw.SizedBox(height: 8),
                _buildRow('Metode Bayar', notif.metodePembayaran),
                _buildRow('Jumlah Bayar', _formatRupiah(notif.totalHarga)),

                pw.SizedBox(height: 24),

                // ---- TOTAL BOX ----
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#EEF3FF'),
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(
                      color: PdfColor.fromHex('#093FB4'),
                      width: 1,
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total Pembayaran',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      pw.Text(
                        _formatRupiah(notif.totalHarga),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                          color: PdfColor.fromHex('#093FB4'),
                        ),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // ---- FOOTER ----
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 6),
                pw.Center(
                  child: pw.Text(
                    'Dokumen ini digenerate otomatis sebagai bukti pembayaran yang sah.',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Simpan ke Documents
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/bukti_booking_${notif.bookingId}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      await OpenFile.open(filePath);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat PDF: $e')));
      }
    }
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#093FB4'),
          ),
        ),
        pw.Divider(color: PdfColor.fromHex('#093FB4'), thickness: 0.5),
      ],
    );
  }

  static pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: const pw.TextStyle(color: PdfColors.grey700),
            ),
          ),
          pw.Text(': '),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
