class RekapBulananSiswa {
  final String bulan;
  final int hariAktif;
  final int jumlahHadir;

  RekapBulananSiswa({
    required this.bulan,
    required this.hariAktif,
    required this.jumlahHadir,
  });

  factory RekapBulananSiswa.fromJson(Map<String, dynamic> json) {
    return RekapBulananSiswa(
      bulan: json['bulan'],
      hariAktif: int.tryParse(json['hari_aktif'].toString()) ?? 0,
      jumlahHadir: int.tryParse(json['jumlah_hadir'].toString()) ?? 0,
    );
  }
}