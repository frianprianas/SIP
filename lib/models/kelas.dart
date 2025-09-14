// File: lib/models/kelas.dart

// Model data untuk merepresentasikan data dari tabel 'kelas'
class Kelas {
  final int id;
  final String namaKelas;
  final String nipy;
  final String? km;
  final String? wkm;

  Kelas({
    required this.id,
    required this.namaKelas,
    required this.nipy,
    this.km,
    this.wkm,
  });

  // Konstruktor factory untuk membuat instance Kelas dari Map (JSON)
  factory Kelas.fromJson(Map<String, dynamic> json) {
    return Kelas(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      namaKelas: json['kelas'] ?? '',
      nipy: json['nipy'] ?? '',
      km: json['km'],
      wkm: json['wkm'],
    );
  }
}