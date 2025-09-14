class Kehadiran {
  final String waktuTap;
  final String status;
  final int id;
  final String nama;
  final String nis;

  Kehadiran({
    required this.id,
    required this.nama,
    required this.waktuTap,
    required this.status,
    required this.nis
  });

  factory Kehadiran.fromJson(Map<String, dynamic> json) {
    // Pastikan nama key di JSON sesuai dengan yang ada di database
    // "id", "waktu_tap", "status"
    return Kehadiran(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      waktuTap: json['waktu_tap']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      status: json['status_kehadiran']?.toString() ?? '',
      nis: json['nis']?.toString() ?? '',
    );
  }
}