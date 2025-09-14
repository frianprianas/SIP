
// File: lib/models/catatan_guru.dart
//import 'package:google_fonts/google_fonts.dart';

// CatatanGuru adalah model data untuk catatan harian guru.
// Model ini mencerminkan struktur tabel di database.
class CatatanGuru {
  final int? id; // Menambahkan ID sebagai primary key, nullable karena ID akan dihasilkan oleh database
  final String nipy;
  final String tanggalCatatan;
  final String catatanText;
  final String? createdAt; // Menambahkan timestamp pembuatan, nullable
  final String? updatedAt; // Menambahkan timestamp pembaruan, nullable

  CatatanGuru({
    this.id,
    required this.nipy,
    required this.tanggalCatatan,
    required this.catatanText,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor untuk membuat objek CatatanGuru dari JSON.
  factory CatatanGuru.fromJson(Map<String, dynamic> json) {
    return CatatanGuru(
      id: json['id'] as int?,
      nipy: json['nipy'] as String,
      tanggalCatatan: json['tanggal_catatan'] as String,
      catatanText: json['catatan_text'] as String,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  // Metode untuk mengkonversi objek CatatanGuru ke JSON.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nipy': nipy,
      'tanggal_catatan': tanggalCatatan,
      'catatan_text': catatanText,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }
}