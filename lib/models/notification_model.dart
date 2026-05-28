class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  bool isRead;

  // Dari tabel bookings
  final String bookingId;
  final String tanggalMain; // tanggal_main
  final String jamMulai; // jam_mulai
  final String jamSelesai; // jam_selesai
  final String totalHarga; // total_harga

  // Dari tabel lapangans
  final String namaLapangan; // nama_lapangan
  final String lokasi; // lokasi

  // Dari tabel users
  final String userName; // name

  // Dari tabel payments
  final String metodePembayaran; // metode_pembayaran
  final String transactionId; // transaction_id

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    required this.bookingId,
    required this.tanggalMain,
    required this.jamMulai,
    required this.jamSelesai,
    required this.totalHarga,
    required this.namaLapangan,
    required this.lokasi,
    required this.userName,
    required this.metodePembayaran,
    required this.transactionId,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      isRead: map['isRead'] ?? false,
      bookingId: map['bookingId'] ?? '',
      tanggalMain: map['tanggalMain'] ?? '',
      jamMulai: map['jamMulai'] ?? '',
      jamSelesai: map['jamSelesai'] ?? '',
      totalHarga: map['totalHarga'] ?? '',
      namaLapangan: map['namaLapangan'] ?? '',
      lokasi: map['lokasi'] ?? '',
      userName: map['userName'] ?? '',
      metodePembayaran: map['metodePembayaran'] ?? '',
      transactionId: map['transactionId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'bookingId': bookingId,
      'tanggalMain': tanggalMain,
      'jamMulai': jamMulai,
      'jamSelesai': jamSelesai,
      'totalHarga': totalHarga,
      'namaLapangan': namaLapangan,
      'lokasi': lokasi,
      'userName': userName,
      'metodePembayaran': metodePembayaran,
      'transactionId': transactionId,
    };
  }
}
