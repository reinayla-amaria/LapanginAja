class Booking {
  final String id;
  final String courtName;
  final String courtId;
  final String userId;
  final String date;
  final String time;
  final String status;
  final double totalPrice;

  Booking({
    required this.id,
    required this.courtName,
    required this.courtId,
    required this.userId,
    required this.date,
    required this.time,
    required this.status,
    required this.totalPrice,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'].toString(),
      // Sesuaikan dengan alias 'nama_lapangan' dari JOIN query
      courtName: json['nama_lapangan'] ?? "Lapangan",
      // Sesuaikan dengan nama kolom 'lapangan_id' di database
      courtId: json['lapangan_id']?.toString() ?? json['court_id'].toString(),
      userId: json['user_id'].toString(),
      // Sesuaikan dengan nama kolom 'tanggal_main' di database
      date: json['tanggal_main']?.toString() ?? json['date'] ?? "",
      // Sesuaikan dengan nama kolom 'jam_mulai' di database
      time: json['jam_mulai']?.toString() ?? json['time'] ?? "",
      status: json['status'] ?? "Pending",
      // Sesuaikan dengan nama kolom 'total_harga' di database
      totalPrice:
          double.tryParse(json['total_harga'].toString()) ??
          double.tryParse(json['total_price'].toString()) ??
          0.0,
    );
  }
}
