import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/court_model.dart';
import 'payment_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BookingScheduleScreen extends StatefulWidget {
  final Court court;

  const BookingScheduleScreen({super.key, required this.court});

  @override
  State<BookingScheduleScreen> createState() => _BookingScheduleScreenState();
}

final List<String> timeList = [
  "08:00 - 09:00",
  "09:00 - 10:00",
  "10:00 - 11:00",
  "11:00 - 12:00",
  "13:00 - 14:00",
  "14:00 - 15:00",
  "15:00 - 16:00",
  "16:00 - 17:00",
  "17:00 - 18:00",
  "19:00 - 20:00",
  "20:00 - 21:00",
  "21:00 - 22:00",  
];

Future<String> _getLoggedInUserId() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id');
  return userId ?? "0";
}

class _BookingScheduleScreenState extends State<BookingScheduleScreen> {
  String? _selectedField;
  String? _selectedTime;
  DateTime? _selectedDate;
  DateTime _focusedMonth = DateTime.now();

  List<Court> _availableCourts = [];
  List<String> _fieldNames = [];
  bool _isLoadingCourts = true;

  @override
  void initState() {
    super.initState();

    _selectedField = null;
    _fetchSiblingCourts();
  }

  Future<void> _fetchSiblingCourts() async {
    if (!mounted) return;
    setState(() => _isLoadingCourts = true);

    try {
      final response = await http.get(
        Uri.parse('https://lapanginaja.web.id/api/lapangan'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        final List<dynamic> allData = result['data'];

        final List<Court> fetchedCourts = allData
            .where(
              (json) => json['mitra_id'].toString() == widget.court.mitraId,
            )
            .map((json) => Court.fromJson(json))
            .toList();

        debugPrint("Lapangan ditemukan: ${fetchedCourts.length}");

        if (mounted) {
          setState(() {
            _availableCourts = fetchedCourts;
            _fieldNames = fetchedCourts.map((c) => c.courtName).toList();
            _isLoadingCourts = false;
            _selectedField = _fieldNames.isNotEmpty ? _fieldNames.first : null;
          });
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoadingCourts = false);
    }
  }

  String _getCurrentCourtImage() {
    if (_availableCourts.isEmpty) return widget.court.imageUrl;
    final selected = _availableCourts.firstWhere(
      (c) => c.name == _selectedField,
      orElse: () => widget.court,
    );
    return selected.imageUrl;
  }

  bool get _isFormValid =>
      _selectedField != null && _selectedTime != null && _selectedDate != null;

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);

    const primaryBlue = Color(0xFF093FB4);
    const accentGreen = Color(0xFF00C853);

    // LOGIKA PEMOTONGAN NAMA UNTUK TAMPILAN
    // Jika _selectedField ada, potong stringnya. Jika tidak, pakai data awal.
    String displayVenueName = widget.court.name;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. HEADER (Logo Only)
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
                  children: [
                    // Tombol Back
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

                    // Logo di Tengah
                    Expanded(
                      child: Center(
                        child: Image.asset('assets/logo_white.png', height: 40),
                      ),
                    ),

                    const SizedBox(width: 40), // Spacer penyeimbang
                  ],
                ),

                const SizedBox(height: 25),

                // Search Bar Hiasan
                TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: "cari lapangan",
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    suffixIcon: const Icon(Icons.search, size: 28),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
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

          // 2. KONTEN SCROLLABLE
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Pilih Jadwal Lapangan",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    displayVenueName,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 140,
                          height: 100,
                          child: Image.network(
                            _getCurrentCourtImage(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, e, s) => Image.asset(
                              'assets/lapangan.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Dropdown Area
                      Expanded(
                        child: Column(
                          children: [
                            // DROPDOWN PILIH LAPANGAN
                            _isLoadingCourts
                                ? const SizedBox(
                                    height: 45,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : _buildDropdown(
                                    "Pilih Lapangan",
                                    _fieldNames,
                                    _selectedField,
                                    (val) {
                                      setState(() => _selectedField = val);
                                    },
                                  ),
                            const SizedBox(height: 10),

                            // Dropdown Pilih Waktu
                            _buildDropdown(
                              "Pilih Waktu",
                              timeList,
                              _selectedTime,
                              (val) => setState(() => _selectedTime = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  _buildDynamicCalendar(),
                  const SizedBox(height: 30),

                  // Tombol Booking
                  // Cari bagian Align di dalam widget build kamu, lalu ganti isinya:
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFormValid
                              ? accentGreen
                              : Colors.grey[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: _isFormValid ? 2 : 0,
                        ),
                        onPressed: _isFormValid && !bookingProvider.isLoading
                            ? _processBooking
                            : null,
                        child: bookingProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Booking Sekarang",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processBooking() async {
    // 1. Ambil Provider

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );

    // 2. Ambil ID (Gunakan getter userId dari AuthProvider yang sudah kita buat tadi)
    String? currentUserId = authProvider.userId;

    // 3. Validasi: Jika ID masih kosong, suruh login ulang
    if (currentUserId == null ||
        currentUserId == "0" ||
        currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sesi login berakhir. Silakan login ulang."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 4. Cari objek lapangan
    Court selectedCourtObj = widget.court;
    if (_availableCourts.isNotEmpty) {
      try {
        selectedCourtObj = _availableCourts.firstWhere(
          (c) => c.name == _selectedField,
        );
      } catch (_) {}
    }

    // 5. Jalankan Booking
    bool success = await bookingProvider.createBooking(
      userId: currentUserId,
      courtId: selectedCourtObj.id,
      date: _selectedDate!,
      time: _selectedTime!,
      duration: 1,
      pricePerHour: selectedCourtObj.pricePerHour,
    );

    if (success && mounted) {
      double total = selectedCourtObj.pricePerHour * 1;
      String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      String snapToken = bookingProvider.lastSnapToken; // ← ambil snap token

      if (success && mounted) {
        // Tambah ini — refresh jadwal setelah booking berhasil
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('user_id') ?? '';
        if (userId.isNotEmpty) {
          bookingProvider.fetchBookings(userId);
        }

        double total = selectedCourtObj.pricePerHour * 1;
        String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        String snapToken = bookingProvider.lastSnapToken;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              bookingId:
                  "BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
              court: selectedCourtObj,
              date: formattedDate,
              time: _selectedTime!,
              totalPrice: total,
              snapToken: snapToken,
            ),
          ),
        );
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            bookingId:
                "BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
            court: selectedCourtObj,
            date: formattedDate,
            time: _selectedTime!,
            totalPrice: total,
            snapToken: snapToken, // ← kirim snap token
          ),
        ),
      );
    }
  }

  // 3. Cek apakah berhasil simpan di MySQL
  // Widget Dropdown
  Widget _buildDropdown(
    String hint,
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(
            hint,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          value: value,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
          items: items.toSet().map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Widget Kalender Dinamis
  Widget _buildDynamicCalendar() {
    final int year = _focusedMonth.year;
    final int month = _focusedMonth.month;
    final int daysInMonth = DateTime(year, month + 1, 0).day;
    final int firstWeekdayOfMonth = DateTime(year, month, 1).weekday;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<String> dayHeaders = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final List<DateTime?> calendarDays = List.generate(
      firstWeekdayOfMonth - 1,
      (index) => null,
    );

    for (int i = 1; i <= daysInMonth; i++) {
      calendarDays.add(DateTime(year, month, i));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header Bulan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    if (_focusedMonth.isAfter(
                      DateTime(today.year, today.month),
                    )) {
                      setState(() {
                        _focusedMonth = DateTime(year, month - 1);
                      });
                    }
                  },
                ),
                Text(
                  DateFormat('MMMM yyyy', 'id_ID').format(_focusedMonth),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(year, month + 1);
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Header Hari
          Row(
            children: dayHeaders
                .map(
                  (day) => Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.grey[50]),
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          // Grid Tanggal
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: calendarDays.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final date = calendarDays[index];

              if (date == null) return const SizedBox();

              bool isPastDate = date.isBefore(today);
              bool isSelected =
                  _selectedDate != null &&
                  date.year == _selectedDate!.year &&
                  date.month == _selectedDate!.month &&
                  date.day == _selectedDate!.day;

              return InkWell(
                onTap: isPastDate
                    ? null
                    : () {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[50] : null,
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: isSelected
                          ? const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF093FB4),
                            )
                          : null,
                      alignment: Alignment.center,
                      child: Text(
                        "${date.day}",
                        style: TextStyle(
                          color: isPastDate
                              ? Colors.grey[300]
                              : (isSelected ? Colors.white : Colors.black87),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          decoration: isPastDate
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
