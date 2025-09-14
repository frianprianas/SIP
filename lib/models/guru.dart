// File: models/guru.dart

class Guru {
  final String nipy;
  final String nama;
  final String? ket; // ✨ Perbaikan: Tambahkan tanda tanya '?' agar properti bisa bernilai null
  final String? email; // ✨ Perbaikan: Tambahkan tanda tanya '?' agar properti bisa bernilai null

  Guru({
    required this.nipy,
    required this.nama,
    this.ket, // ✨ Perbaikan: Hapus 'required' karena properti ini tidak wajib ada
    this.email, // ✨ Perbaikan: Hapus 'required' karena properti ini tidak wajib ada
  });

  factory Guru.fromJson(Map<String, dynamic> json) {
    // ✨ Perbaikan: Gunakan 'as String?' untuk cast yang aman.
    // Jika nilai dari server adalah null, maka akan diterima sebagai null.
    // Jika nilai dari server adalah string, maka akan diterima sebagai string.
    return Guru(
      nipy: json['nipy'] as String,
      nama: json['nama'] as String,
      ket: json['ket'] as String?,
      email: json['email'] as String?,
    );
  }
}

