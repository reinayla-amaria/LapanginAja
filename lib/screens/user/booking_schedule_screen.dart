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

class _BookingScheduleScreenState extends State<BookingScheduleScreen> {
  String? _selectedField;
  String? _selectedTime;
  DateTime? _selectedDate;
  DateTime _focusedMonth = DateTime.now();
  List<Court> _availableCourts = [];
  List<String> _fieldNames = [];
  List<String> _bookedSlots = [];
  bool _isLoadingCourts = true;

  @override
  void initState() {
    super.initState();
    _selectedField = null;
    _fetchSiblingCourts();
  }

  Future<void> _fetchBookedSlots() async {
    if (_selectedDate == null || _selectedField == null) return;
    final selectedCourt = _availableCourts.firstWhere(
      (c) => c.courtName == _selectedField,
      orElse: () => widget.court,
    );
    final tanggal = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    try {
      final response = await http.get(
        Uri.parse(
          'https://lapanginaja.web.id/api/lapangan/${selectedCourt.id}/availability?tanggal=$tanggal',
        ),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final List<dynamic> data = result['data'];
        setState(() {
          _bookedSlots = data.map((b) {
            final jam = DateTime.parse(b['jam_mulai']);
            return DateFormat('HH:mm').format(jam);
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetch availability: $e");
    }
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
    String displayVenueName = widget.court.name;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
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
                      Expanded(
                        child: Column(
                          children: [
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
                                      _fetchBookedSlots();
                                    },
                                  ),
                            const SizedBox(height: 10),
                            _buildTimeDropdown(),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  _buildDynamicCalendar(),
                  const SizedBox(height: 30),

                  SizedBox(
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );
    String? currentUserId = authProvider.userId;

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

    Court selectedCourtObj = widget.court;
    if (_availableCourts.isNotEmpty) {
      try {
        selectedCourtObj = _availableCourts.firstWhere(
          (c) => c.courtName == _selectedField,
        );
      } catch (_) {}
    }

    bool success = await bookingProvider.createBooking(
      userId: currentUserId,
      courtId: selectedCourtObj.id,
      date: _selectedDate!,
      time: _selectedTime!,
      duration: 1,
      pricePerHour: selectedCourtObj.pricePerHour,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bookingProvider.errorMessage.isNotEmpty
                ? bookingProvider.errorMessage
                : 'Booking gagal. Silakan coba lagi.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (success && mounted) {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      if (userId.isNotEmpty) bookingProvider.fetchBookings(userId);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            bookingId: bookingProvider.lastBookingId,
            court: selectedCourtObj,
            date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
            time: _selectedTime!,
            totalPrice: selectedCourtObj.pricePerHour * 1,
            snapToken: bookingProvider.lastSnapToken,
          ),
        ),
      );
    }
  }

  Widget _buildTimeDropdown() {
    final now = DateTime.now();
    final isToday =
        _selectedDate != null &&
        _selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day;

    // ✅ Reset _selectedTime kalau jam yang dipilih sudah lewat
    if (isToday && _selectedTime != null) {
      final jamMulai = _selectedTime!.split(' - ')[0];
      final parts = jamMulai.split(':');
      final slotTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      if (slotTime.isBefore(now)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() => _selectedTime = null);
        });
      }
    }

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
          hint: const Text(
            "Pilih Waktu",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          value: _selectedTime,
          items: timeList.map((String time) {
            final jamMulai = time.split(' - ')[0];
            final isBooked = _bookedSlots.contains(jamMulai);

            bool isPast = false;
            if (isToday) {
              final parts = jamMulai.split(':');
              final slotTime = DateTime(
                now.year,
                now.month,
                now.day,
                int.parse(parts[0]),
                int.parse(parts[1]),
              );
              isPast = slotTime.isBefore(now);
            }

            final isDisabled = isBooked || isPast;

            return DropdownMenuItem<String>(
              value: time, // ✅ selalu pakai value asli, bukan null
              enabled: !isDisabled,
              child: Text(
                isBooked
                    ? '$time (Penuh)'
                    : isPast
                    ? '$time (Lewat)'
                    : time,
                style: TextStyle(
                  fontSize: 13,
                  color: isDisabled ? Colors.grey[400] : Colors.black87,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val == null) return;
            // Cek lagi sebelum set, jaga-jaga
            final jamMulai = val.split(' - ')[0];
            final isBooked = _bookedSlots.contains(jamMulai);
            bool isPast = false;
            if (isToday) {
              final parts = jamMulai.split(':');
              final slotTime = DateTime(
                now.year,
                now.month,
                now.day,
                int.parse(parts[0]),
                int.parse(parts[1]),
              );
              isPast = slotTime.isBefore(now);
            }
            if (!isBooked && !isPast) {
              setState(() => _selectedTime = val);
            }
          },
        ),
      ),
    );
  }

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
    for (int i = 1; i <= daysInMonth; i++)
      calendarDays.add(DateTime(year, month, i));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
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
                      setState(() => _focusedMonth = DateTime(year, month - 1));
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
                  onPressed: () =>
                      setState(() => _focusedMonth = DateTime(year, month + 1)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
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
                        setState(() => _selectedDate = date);
                        _fetchBookedSlots();
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
