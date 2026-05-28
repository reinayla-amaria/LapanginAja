import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/notification_screen.dart';
import '../../providers/booking_provider.dart';
import '../../models/court_model.dart';
import '../../models/booking_models.dart';
import 'court_detail_screen.dart';
import '../../providers/notification_provider.dart';
import '../../services/fcm_services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userName;

  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FcmService.initialize(context);
    });
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('user_id');
    final String? name = prefs.getString('user_name');

    await prefs.remove('notifications');
    if (mounted) {
      setState(() => _userName = name);

      final bookingProv = Provider.of<BookingProvider>(context, listen: false);

      bookingProv.fetchCourts();

      if (userId != null && userId.isNotEmpty) {
        debugPrint("Loading bookings for User ID: $userId");
        bookingProv.fetchBookings(userId);
      } else {
        debugPrint("User ID tidak ditemukan di SharedPreferences");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProv = Provider.of<BookingProvider>(context);
    final List<Booking> myBookings = bookingProv.bookings;
    final List<Court> allCourts = bookingProv.courts;
    final notifProv = Provider.of<NotificationProvider>(context);
    final List<Court> uniqueVenues = [];
    final Set<String> seenVenues = {};

    for (var court in allCourts) {
      String venueName = court.name.contains(' - ')
          ? court.name.split(' - ')[0].trim()
          : court.name.trim();

      bool matchesSearch = venueName.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );

      if (!seenVenues.contains(venueName) && matchesSearch) {
        seenVenues.add(venueName);
        uniqueVenues.add(court);
      }
    }

    const primaryBlue = Color(0xFF093FB4);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // 1. HEADER
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // LOGO
                    Image.asset('assets/logo_white.png', height: 40),

                    // NOTIF + PROFILE
                    Row(
                      children: [
                        // NOTIFICATION BUTTON
                        Stack(
                          children: [
                            IconButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationScreen(),
                                  ),
                                );
                                // Refresh badge setelah balik dari halaman notif
                                if (context.mounted) {
                                  Provider.of<NotificationProvider>(
                                    context,
                                    listen: false,
                                  ).loadNotifications();
                                }
                              },
                              icon: const Icon(
                                Icons.notifications_none,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            // Badge hanya muncul kalau ada notif belum dibaca
                            if (notifProv.unreadCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    notifProv.unreadCount > 9
                                        ? '9+'
                                        : '${notifProv.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(width: 8),

                        // PROFILE PICTURE
                        GestureDetector(
                          onTap: () {
                            print("Profile clicked");
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              image: const DecorationImage(
                                image: AssetImage('assets/anime 1.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ), // end Row (notif + profile)
                  ],
                ), // end Row (logo + icons)

                const SizedBox(height: 20),

                // SEARCH BAR
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
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
            ), // end Column (header content)
          ), // end Container (header)
          // 2. SCROLLABLE CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_searchQuery.isEmpty) ...[
                    _buildPromoBanner(),
                    const SizedBox(height: 25),
                  ],

                  // SECTION 1: DAFTAR LAPANGAN
                  const Text(
                    "Daftar Lapangan",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  SizedBox(
                    height: 270,
                    child: bookingProv.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : uniqueVenues.isEmpty
                        ? Center(
                            child: Text(
                              "Lapangan '$_searchQuery' tidak ditemukan.",
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: uniqueVenues.length,
                            itemBuilder: (context, index) {
                              return _buildHorizontalCourtCard(
                                context,
                                uniqueVenues[index],
                                primaryBlue,
                              );
                            },
                          ),
                  ),

                  // SECTION 2: JADWAL KAMU
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 25),
                    const Text(
                      "Jadwal Kamu",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (myBookings.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          "Belum ada jadwal booking.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      Column(
                        children: myBookings
                            .take(3)
                            .map((booking) => _buildScheduleCard(booking))
                            .toList(),
                      ),
                    const SizedBox(height: 50),
                  ],
                ],
              ),
            ),
          ), // end Expanded
        ],
      ),
    );
  }

  // --- WIDGET HELPER: Court Card ---
  Widget _buildHorizontalCourtCard(
    BuildContext context,
    Court court,
    Color primaryColor,
  ) {
    String venueName = court.name.split(' - ')[0].trim();

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16, bottom: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venueName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        court.location,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // IMAGE
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  court.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
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
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/lapangan.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              width: double.infinity,
              height: 30,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.zero,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourtDetailScreen(court: court),
                    ),
                  );
                },
                child: const Text(
                  "Lihat Lapangan",
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: Schedule Card ---
  Widget _buildScheduleCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: booking.status == 'Lunas'
              ? Colors.green.shade200
              : Colors.orange.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.courtName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: booking.status == 'Lunas'
                      ? Colors.green
                      : Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  booking.status,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text(booking.date, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 15),
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Text(booking.time, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: Promo Banner ---
  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 100,
            child: Image.asset('assets/anime 1.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Waktunya olahraga!",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  "BOOKING LAPANGAN MU SEKARANG!",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    "Booking Sekarang!",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
