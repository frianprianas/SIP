class Siswa {
  final String nis;
  final String nama;
  final String kelas;
  final String email;

  Siswa({
    required this.nis,
    required this.nama,
    required this.kelas,
    required this.email,
  });

  factory Siswa.fromJson(Map<String, dynamic> json) {
    return Siswa(
      nis: json['nis'] ?? '',
      nama: json['nama'] ?? '',
      kelas: json['kelas'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nis': nis,
      'nama': nama,
      'kelas': kelas,
      'email': email,
    };
  }
}