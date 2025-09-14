class Catatan {
  final int? id; // ID bisa null jika catatan baru
  final String nis;
  final String tanggalCatatan; // Format YYYY-MM-DD
  final String catatanText;

  Catatan({
    this.id,
    required this.nis,
    required this.tanggalCatatan,
    required this.catatanText,
  });

  factory Catatan.fromJson(Map<String, dynamic> json) {
    return Catatan(
      id: int.tryParse(json['id'].toString()),
      nis: json['nis'] ?? '',
      tanggalCatatan: json['tanggal_catatan'] ?? '',
      catatanText: json['catatan_text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // Sertakan ID jika ada (untuk update/delete)
      'nis': nis,
      'tanggal_catatan': tanggalCatatan,
      'catatan_text': catatanText,
    };
  }
}
