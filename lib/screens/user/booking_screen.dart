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
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<BookingProvider>(context, listen: false).fetchCourts(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingProv = Provider.of<BookingProvider>(context);

    // Filter pencarian sederhana

    final Map<String, Court> uniqueMitra = {};

    for (final court in bookingProv.courts) {
      uniqueMitra.putIfAbsent(court.mitraId, () => court);
    }

    final List<Court> filteredCourts = uniqueMitra.values.where((court) {
      return court.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              left: 24,
              right: 24,
              bottom: 30,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF093FB4),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // LOGO
                    Image.asset('assets/logo_white.png', height: 40),

                    // PROFIL (tanpa notif karena ini halaman booking)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        image: const DecorationImage(
                          image: AssetImage('assets/anime 1.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // SEARCH BAR
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: "Cari nama lapangan...",
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

          // JUDUL
          const Padding(
            padding: EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Pilih Arena Lapangan",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // LIST VENUE
          Expanded(
            child: bookingProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredCourts.isEmpty
                ? const Center(child: Text("Tidak ada venue ditemukan"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredCourts.length,
                    itemBuilder: (context, index) =>
                        _buildVenueCard(context, filteredCourts[index]),
                  ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET KARTU VENUE ---

  Widget _buildVenueCard(BuildContext context, Court court) {
    String venueNameOnly = court.name;

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
                  debugPrint("Gagal load gambar: ${court.imageUrl}");

                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 40),
                    ),
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
