import 'package:shared_preferences/shared_preferences.dart';
import '../models/siswa.dart';
import '../models/guru.dart'; // Jangan lupa import model Guru

class AuthManager {
  // Kunci-kunci untuk Shared Preferences
  static const _kLoggedInKey = 'is_logged_in';
  static const _kUserTypeKey = 'user_type';
  static const _kNisKey = 'nis_siswa_login';
  static const _kNipyKey = 'nipy_guru_login'; // Kunci baru yang sudah diperbaiki untuk NIPY Guru
  static const _kLoginTimeKey = 'login_time';

  // --- Fungsi Baru: Menyimpan status login Guru ---
  static Future<void> saveGuruLoginStatus(Guru guru) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedInKey, true);
    await prefs.setString(_kUserTypeKey, 'guru'); // Simpan tipe pengguna
    await prefs.setString(_kNipyKey, guru.nipy); // Menggunakan nipy
    await prefs.setInt(_kLoginTimeKey, DateTime.now().millisecondsSinceEpoch);
  }
  
  // --- Fungsi yang diperbarui: Menyimpan status login Siswa ---
  static Future<void> saveSiswaLoginStatus(Siswa siswa) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedInKey, true);
    await prefs.setString(_kUserTypeKey, 'siswa'); // Simpan tipe pengguna
    await prefs.setString(_kNisKey, siswa.nis);
    await prefs.setInt(_kLoginTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Method untuk memeriksa apakah pengguna sudah login dan sesinya masih valid
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final bool? isLoggedInStatus = prefs.getBool(_kLoggedInKey);
    final int? loginTime = prefs.getInt(_kLoginTimeKey);
    final String? userType = prefs.getString(_kUserTypeKey);

    if (isLoggedInStatus != true || loginTime == null || userType == null) {
      return false;
    }

    // Periksa apakah sesi sudah kadaluarsa (misal: lebih dari 7 hari)
    final savedTime = DateTime.fromMillisecondsSinceEpoch(loginTime);
    final duration = DateTime.now().difference(savedTime);
    const sessionDurationDays = 7;
    if (duration.inDays > sessionDurationDays) {
      await clearLoginStatus();
      return false;
    }
    
    return true;
  }

  // Method untuk mendapatkan tipe pengguna yang sedang login
  static Future<String?> getLoggedInUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserTypeKey);
  }

  // Method untuk mendapatkan NIS dari sesi yang tersimpan
  static Future<String?> getUserNis() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kNisKey);
  }

  // Method untuk mendapatkan NIPY dari sesi yang tersimpan
  static Future<String?> getUserNipy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kNipyKey);
  }
  
  // --- PERBAIKAN: Hapus semua kunci yang berhubungan dengan login ---
  static Future<void> clearLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoggedInKey);
    await prefs.remove(_kUserTypeKey);
    await prefs.remove(_kNisKey);
    await prefs.remove(_kNipyKey);
    await prefs.remove(_kLoginTimeKey);
  }
}