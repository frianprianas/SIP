class Jadwal {
  final String id;
  // Mengganti mataPelajaran dengan namaHari karena itu yang ada di tabel Anda
  final String namaHari; 
  final String jamMasuk;
  final String jamPulang;
  final String hari; // Ini kemungkinan adalah representasi teks dari hari (misal: "Senin")

  Jadwal({
    required this.id,
    required this.namaHari, // Sesuaikan di sini
    required this.jamMasuk,
    required this.jamPulang,
    required this.hari,
  });

  factory Jadwal.fromJson(Map<String, dynamic> json) {
    return Jadwal(
      id: json['id'].toString(),
      namaHari: json['nama_hari'], // Sesuaikan dengan kunci dari PHP
      jamMasuk: json['jam_masuk'],
      jamPulang: json['jam_pulang'],
      hari: json['nama_hari'], // Menggunakan nama_hari sebagai representasi hari
    );
  }
}