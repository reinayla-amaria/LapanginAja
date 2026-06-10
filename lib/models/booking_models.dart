class Booking {
  final String id;
  final String courtName;
  final String courtId;
  final String userId;
  final String date;
  final String time;
  final String status;
  final double totalPrice;
  final String? userName;
  final String? transactionId;
  final String? mitraId;
  final String? mitraName;

  Booking({
    required this.id,
    required this.courtName,
    required this.courtId,
    required this.userId,
    required this.date,
    required this.time,
    required this.status,
    required this.totalPrice,
    this.userName,
    this.transactionId,
    this.mitraId,
    this.mitraName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final data = json.containsKey('data') ? json['data'] : json;
    final booking = data['booking'] ?? data;
    final lapangan = data['lapangan'] ?? {};
    final user = data['user'] ?? {};
    final payment = data['payment'] ?? {};
    final mitra = lapangan['mitra'] ?? {};

    return Booking(
      id: booking['id']?.toString() ?? "",
      courtName:
          lapangan['nama_lapangan'] ?? booking['nama_lapangan'] ?? "Lapangan",
      courtId: booking['lapangan_id']?.toString() ?? "",
      userId: booking['user_id']?.toString() ?? "",
      date: booking['tanggal_main'] ?? "",
      time: booking['jam_mulai'] ?? "",
      status: booking['status'] ?? "Pending",
      totalPrice:
          double.tryParse(booking['total_harga']?.toString() ?? "0") ?? 0.0,
      userName: user['name'] ?? "Penyewa",
      transactionId: payment['transaction_id'] ?? "-",
      // Cek flat format dulu (dari /my-bookings), baru nested
      mitraId: booking['mitra_id']?.toString() ?? mitra['id']?.toString() ?? "",
      mitraName:
          booking['mitra_name']?.toString() ?? mitra['name']?.toString() ?? "",
    );
  }
}
