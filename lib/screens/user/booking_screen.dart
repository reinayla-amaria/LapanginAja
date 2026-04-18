import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/court_model.dart';
import 'court_detail_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Variabel Pencarian
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ambil data terbaru saat halaman dibuka
    Future.microtask(
      () => Provider.of<BookingProvider>(context, listen: false).fetchCourts(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingProv = Provider.of<BookingProvider>(context);
    final List<Court> allCourts = bookingProv.courts;

    // --- LOGIKA FILTER: UNIK VENUE & PENCARIAN ---
    final Set<String> seenVenues = {};
    final List<Court> uniqueVenues = [];

    for (var court in allCourts) {
      // Ambil nama venue saja (Hapus " - Lapangan X")
      String venueName = court.name.split(' - ')[0].trim();

      // Cek apakah cocok dengan pencarian
      bool matchesSearch = venueName.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );

      // Jika venue belum ada di list DAN cocok dengan pencarian -> Tambahkan
      if (!seenVenues.contains(venueName) && matchesSearch) {
        seenVenues.add(venueName);
        uniqueVenues.add(court);
      }
    }
    // ---------------------------------------------

    const primaryBlue = Color(0xFF093FB4);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // 1. HEADER (Logo Only & Search)
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              left: 24,
              right: 24,
              bottom: 30,
            ),
            decoration: const BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Logo Putih
                Image.asset('assets/logo_white.png', height: 40),

                const SizedBox(height: 20),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Cari venue...",
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: const Icon(Icons.search, color: Colors.black),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = "");
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. JUDUL SECTION
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                "Pilih Venue",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 3. LIST VENUE
          Expanded(
            child: bookingProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : uniqueVenues.isEmpty
                ? Center(child: Text("Venue '$_searchQuery' tidak ditemukan."))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: uniqueVenues.length,
                    itemBuilder: (context, index) {
                      return _buildVenueCard(context, uniqueVenues[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET KARTU VENUE ---
  Widget _buildVenueCard(BuildContext context, Court court) {
    // Bersihkan nama lapangan agar hanya nama Gedung
    String venueNameOnly = court.name.split(' - ')[0].trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // A. GAMBAR VENUE (Kiri)
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Image.network(
                court.imageUrl, // 1. Coba load URL dari Supabase
                fit: BoxFit.cover,

                // 2. Loading Indicator
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },

                // 3. Fallback jika Gagal (Tampilkan aset lokal)
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/lapangan.png', // Pastikan file ini ada
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
          ),

          // B. INFO VENUE (Kanan)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Venue (Sudah dipotong)
                  Text(
                    venueNameOnly,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Lokasi
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          court.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Tombol Pilih
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        minimumSize: const Size(0, 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        // Navigasi ke Detail
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CourtDetailScreen(court: court),
                          ),
                        );
                      },
                      child: const Text(
                        "Pilih Lapanganmu!",
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
