
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mysql1/mysql1.dart';
import '../../models/court_model.dart';
import 'payment_screen.dart';
import '../../services/db_connection.dart';

class BookingScheduleScreen extends StatefulWidget {
  final Court court;
  const BookingScheduleScreen({super.key, required this.court});

  @override
  State<BookingScheduleScreen> createState() => _BookingScheduleScreenState();
}

class _BookingScheduleScreenState extends State<BookingScheduleScreen> {
  String? _selectedField;
  String? _selectedTime;
  DateTime? _selectedDate;
  DateTime _focusedMonth = DateTime.now();

  List<Court> _availableCourts = [];
  List<String> _fieldNames = [];
  bool _isLoadingCourts = true;

  final List<String> timeList = [
    '08:00 - 09:00',
    '09:00 - 10:00',
    '10:00 - 11:00',
    '16:00 - 17:00',
    '19:00 - 20:00',
    '20:00 - 21:00',
  ];

  @override
  void initState() {
    super.initState();
    _selectedField = widget.court.name;
    _fetchSiblingCourts();
  }

  Future<void> _fetchSiblingCourts() async {
  setState(() => _isLoadingCourts = true);

  try {
    String venueName = widget.court.name.split(' - ')[0].trim();

    final conn = await DBService.getConnection();

    Results results = await conn.query(
      "SELECT id, nama_lapangan, harga_per_jam, foto, lokasi FROM lapangans WHERE nama_lapangan LIKE ? ORDER BY nama_lapangan ASC",
      ['$venueName%'],
    );

    final List<Court> fetchedCourts = results.map((row) {
      return Court(
        id: row['id'].toString(),
        name: row['nama_lapangan'] ?? '',
        location: row['lokasi'] ?? '',
        pricePerHour: row['harga_per_jam'] != null
            ? (row['harga_per_jam'] as num).toDouble()
            : 0.0,
        imageUrl: row['foto'] ?? '',
        facilities: [],      // tidak ada di tabel lapangans
        description: '',     // tidak ada di tabel lapangans
      );
    }).toList();

    await conn.close();

    setState(() {
      _availableCourts = fetchedCourts;
      _fieldNames = fetchedCourts.map((c) => c.name).toList();
      _isLoadingCourts = false;

      if (!_fieldNames.contains(_selectedField) && _fieldNames.isNotEmpty) {
        _selectedField = _fieldNames.first;
      }
    });
  } catch (e) {
    debugPrint("Error fetching lapangans: $e");
    setState(() {
      _isLoadingCourts = false;
      _fieldNames = [widget.court.name];
    });
  }
}

String _getCurrentCourtImage() {
    if (_availableCourts.isEmpty) return widget.court.imageUrl;
    try {
      return _availableCourts
          .firstWhere((c) => c.name == _selectedField)
          .imageUrl;
    } catch (e) {
      return widget.court.imageUrl;
    }
  }

  bool get _isFormValid =>
      _selectedField != null && _selectedTime != null && _selectedDate != null;

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1565C0);
    const accentGreen = Color(0xFF00C853);

    // LOGIKA PEMOTONGAN NAMA UNTUK TAMPILAN
    // Jika _selectedField ada, potong stringnya. Jika tidak, pakai data awal.
    String displayVenueName = _selectedField != null
        ? _selectedField!.split(' - ')[0].trim()
        : widget.court.name.split(' - ')[0].trim();

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
                        child: Image.asset(
                          'assets/logo_white.png',
                          height: 40,
                        ),
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
                  const SizedBox(height: 5),

                  // Tampilkan HANYA Nama Venue (Misal: "Kelapa Gading")
                  Text(
                    displayVenueName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Area Gambar & Dropdown
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  
ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: SizedBox(
    width: 140,
    height: 100,
    child: Builder(
      builder: (context) {
        final imageUrl = _getCurrentCourtImage();
        if (imageUrl.isEmpty) {
          return Image.asset(
            'assets/lapangan.png',
            fit: BoxFit.cover,
          );
        }
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/lapangan.png',
              fit: BoxFit.cover,
            );
          },
        );
      },
    ),
  ),
),

                      const SizedBox(width: 16),

                      // Dropdown Area
                      Expanded(
                        child: Column(
                          children: [
                            // Dropdown Pilih Lapangan
                            _isLoadingCourts
                                ? const LinearProgressIndicator()
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

                  // KALENDER DINAMIS
                  _buildDynamicCalendar(),

                  const SizedBox(height: 30),

                  // Tombol Booking
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
                        onPressed: _isFormValid ? _processBooking : null,
                        child: const Text(
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

  // Fungsi Proses Booking
  void _processBooking() {
    Court selectedCourtObj = widget.court;
    if (_availableCourts.isNotEmpty) {
      try {
        selectedCourtObj = _availableCourts.firstWhere(
          (c) => c.name == _selectedField,
        );
      } catch (_) {}
    }

    double total = selectedCourtObj.pricePerHour * 1;
    // Format tanggal ke String YYYY-MM-DD
    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          bookingId:
              "BOOK-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
          court: selectedCourtObj,
          date: formattedDate,
          time: _selectedTime!,
          totalPrice: total,
        ),
      ),
    );
  }

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
                              color: Colors.blue,
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
