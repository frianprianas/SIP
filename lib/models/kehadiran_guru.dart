// File: lib/models/kehadiran_guru.dart
//import 'package:google_fonts/google_fonts.dart';

// KehadiranGuru adalah model data untuk catatan kehadiran guru.
// Model ini mencerminkan struktur tabel di database.
class KehadiranGuru {
  final int id; // ID, nullable karena akan dibuat oleh database
  final String nipy;
  final String rfidUid;
  final String waktuTap;
  final String status;
  final String keterangan;

  KehadiranGuru({
    required this.id,
    required this.nipy,
    required this.rfidUid,
    required this.waktuTap,
    required this.status,
    required this.keterangan,
  });

  // Factory constructor untuk membuat objek KehadiranGuru dari JSON.
  factory KehadiranGuru.fromJson(Map<String, dynamic> json) {
    return KehadiranGuru(
      id: json['id'] as int? ?? 0,
      nipy: json['nipy'] as String? ?? '',
      rfidUid: json['rfid_uid'] as String? ?? '',
      waktuTap: json['waktu_tap'] as String? ?? '',
      status: json['status'] as String? ?? '',
      keterangan: json['keterangan'] as String? ??'',
    );
  }

  // Metode untuk mengkonversi objek KehadiranGuru ke JSON.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nipy': nipy,
      'rfid_uid': rfidUid,
      'waktu_tap': waktuTap,
      'status': status,
      'keterangan': keterangan,
    };
    data['id'] = id;
      return data;
  }
}