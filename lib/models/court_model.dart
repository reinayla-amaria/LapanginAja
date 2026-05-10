class Court {
  final String id;
  final String mitraId; // ← BARU
  final String name;
  final String courtName; // ← BARU
  final String location;
  final double pricePerHour;
  final String imageUrl;
  final List<String> facilities;
  final String description;

  Court({
    required this.id,
    required this.mitraId, // ← BARU
    required this.name,
    required this.courtName, // ← BARU
    required this.location,
    required this.pricePerHour,
    required this.imageUrl,
    required this.facilities,
    required this.description,
  });

  factory Court.fromJson(Map<String, dynamic> json) {
    var mitraData = json['mitra'];

    return Court(
      id: json['id'].toString(),
      mitraId: json['mitra_id'].toString(), // ← BARU
      name: mitraData != null
          ? mitraData['name']
          : (json['nama_lapangan'] ?? "Tanpa Nama"),
      courtName: json['nama_lapangan'] ?? "Lapangan", // ← BARU
      location: json['lokasi'] ?? "Lokasi tidak tersedia",
      pricePerHour: double.tryParse(json['harga_per_jam'].toString()) ?? 0.0,
      imageUrl:
          (json['foto'] != null && json['foto'] != "NULL" && json['foto'] != "")
          ? "https://lapanginaja.web.id/storage/${json['foto']}"
          : "https://via.placeholder.com/150",
      facilities: json['facilities'] != null
          ? List<String>.from(json['facilities'])
          : ["Parkir", "Toilet"],
      description: json['description'] ?? "Lapangan olahraga berkualitas.",
    );
  }
}
