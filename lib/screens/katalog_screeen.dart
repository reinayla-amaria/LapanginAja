import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class KatalogScreen extends StatefulWidget {
  @override
  _KatalogScreenState createState() => _KatalogScreenState();
}

class _KatalogScreenState extends State<KatalogScreen> {
  // Bikin list kosong buat nampung data dari Laravel
  List lapangans = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLapangan(); // Panggil fungsi ngambil data pas halaman dibuka
  }

  Future<void> fetchLapangan() async {
    // AWAS BANG: Kalau pake Emulator Android, pakenya 10.0.2.2
    // Kalau pake HP asli dicolok kabel, ganti pake IP WiFi laptop lu
    final url = Uri.parse('http://10.0.2.2:8000/api/lapangan');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          // Kita ambil isian dari key 'data' yang dikirim JSON tadi
          lapangans = jsonData['data'];
          isLoading = false; // Matiin loading
        });
      } else {
        print('Gagal load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error ngab: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cari Lapangan'),
        backgroundColor: Colors.blue[900],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            ) // Tunjukin muter-muter pas loading
          : ListView.builder(
              itemCount: lapangans.length,
              itemBuilder: (context, index) {
                final lapangan = lapangans[index];

                // Ambil nama GOR dari relasi JSON ('mitra' -> 'name')
                final namaGor = lapangan['mitra'] != null
                    ? lapangan['mitra']['name']
                    : 'GOR Unknown';

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(
                      lapangan['nama_lapangan'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        Text('📍 $namaGor'),
                        Text('💰 Rp ${lapangan['harga_per_jam']} / Jam'),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // Nanti ini lu arahin ke halaman Detail / Booking
                      },
                      child: Text('Booking'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
