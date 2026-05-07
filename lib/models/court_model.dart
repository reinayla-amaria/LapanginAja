class Court {
  final String id;
  final String name;
  final String location;
  final double pricePerHour;
  final String imageUrl;
  final List<String> facilities;
  final String description;

  Court({
    required this.id,
    required this.name,
    required this.location,
    required this.pricePerHour,
    required this.imageUrl,
    required this.facilities,
    required this.description,
  });

  factory Court.fromJson(Map<String, dynamic> json) {
    return Court(
      id: json['id'].toString(),
      // 1. Nama Lapangan
      name: json['nama_lapangan'] ?? "Tanpa Nama",
      // 2. Lokasi
      location: json['lokasi'] ?? "Lokasi tidak tersedia",
      // 3. Harga (Gunakan tryParse agar lebih aman dari error format)
      pricePerHour: double.tryParse(json['harga_per_jam'].toString()) ?? 0.0,
      // 4. Foto (Cek jika foto null atau string "NULL")
      imageUrl:
          (json['foto'] != null && json['foto'] != "NULL" && json['foto'] != "")
          ? json['foto']
          : "https://via.placeholder.com/150",
      // 5. Fasilitas & Deskripsi (Default karena belum ada di DB)
      facilities: json['facilities'] != null
          ? List<String>.from(json['facilities'])
          : ["Parkir", "Toilet"],
      description: json['description'] ?? "Lapangan olahraga berkualitas.",
    );
  }
}
