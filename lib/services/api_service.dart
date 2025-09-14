// File: lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sip_siswa/models/kelas.dart';
import '../models/siswa.dart';
import '../models/jadwal.dart';
import '../models/kehadiran.dart';
import '../utils/constants.dart';
import '../models/catatan.dart';
import '../models/guru.dart';
import '../models/catatan_guru.dart';
import '../models/kehadiran_guru.dart';
import '../models/rekap_bulanan_siswa.dart';

class ApiService {
  final String _baseUrl = AppConstants.baseUrl;

  /// Metode internal untuk menangani login, mengurangi duplikasi kode.
  Future<Map<String, dynamic>> _performLogin(String email, String password, String endpoint) async {
    final url = Uri.parse('$_baseUrl/auth/$endpoint');
    print('Attempting to login to URL: $url');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          // Explicitly cast the decoded JSON to a Map<String, dynamic>
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          if (responseData['success'] == true) {
            final dynamic userData = responseData['data'];
            
            // Logika validasi data untuk mencegah crash jika API salah merespons
            if (endpoint.contains('guru')) {
              if (userData == null || userData['nipy'] == null) {
                return {'success': false, 'message': 'Gagal login: data guru tidak valid dari server.'};
              }
              final Guru guru = Guru.fromJson(userData as Map<String, dynamic>);
              return {'success': true, 'message': responseData['message'], 'data': guru};
            } else {
              if (userData == null || userData['nis'] == null) {
                return {'success': false, 'message': 'Gagal login: data siswa tidak valid dari server.'};
              }
              final Siswa siswa = Siswa.fromJson(userData as Map<String, dynamic>);
              return {'success': true, 'message': responseData['message'], 'data': siswa};
            }
          } else {
            return {'success': false, 'message': responseData['message'] ?? 'Login gagal. Silakan coba lagi.'};
          }
        } on FormatException catch (e) {
          print('Error decoding JSON: $e');
          return {'success': false, 'message': 'Gagal memproses data dari server. Format tidak valid.'};
        }
      } else {
        return {'success': false, 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      print('Error during API call: $e');
      return {'success': false, 'message': 'Terjadi kesalahan jaringan atau server.'};
    }
  }

  /// Metode untuk login siswa.
  Future<Map<String, dynamic>> loginSiswa(String email, String password) async {
    return _performLogin(email, password, 'login.php');
  }

  /// Metode untuk login guru.
  Future<Map<String, dynamic>> loginGuru(String email, String password) async {
    return _performLogin(email, password, 'login_guru.php');
  }

  /// Metode untuk mengambil data siswa berdasarkan NIS.
  Future<Siswa> getSiswaByNis(String nis) async {
    final url = Uri.parse('$_baseUrl/siswa/get_siswa_by_nis.php?nis=$nis');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] != null) {
          return Siswa.fromJson(responseData['data'] as Map<String, dynamic>);
        } else {
          throw Exception(responseData['message'] ?? 'Data siswa tidak ditemukan.');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi atau parsing: $e');
    }
  }
  
  /// Metode untuk mengambil data guru berdasarkan NIPY.
  Future<Guru> getGuruByNipy(String nipy) async {
    final url = Uri.parse('$_baseUrl/guru/get_guru_by_nipy.php?nipy=$nipy');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] != null) {
          return Guru.fromJson(responseData['data'] as Map<String, dynamic>);
        } else {
          throw Exception(responseData['message'] ?? 'Data guru tidak ditemukan.');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi atau parsing: $e');
    }
  }

  /// Metode untuk mengambil data jadwal.
  Future<List<Jadwal>> getJadwal() async {
    final url = Uri.parse('$_baseUrl/jadwal/get.php');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true) {
          List<dynamic> jadwalJson = responseData['data'];
          return jadwalJson.map((json) => Jadwal.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          print('API Error (getJadwal): ${responseData['message']}');
          return [];
        }
      } else {
        print('HTTP Error (getJadwal): ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error during getJadwal: $e');
      return [];
    }
  }
  
  /// Metode untuk mengirim FCM token.
  Future<Map<String, dynamic>> registerFCMToken(String id, String token, String userType) async {
    final url = Uri.parse('$_baseUrl/register_fcm_token.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'user_type': userType,
          'device_token': token
        }),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        print('FCM Token Registration Response: $responseData');
        return responseData;
      } else {
        print('HTTP Error registering FCM token: ${response.statusCode}');
        return {"success": false, "message": "Server error: ${response.statusCode}"};
      }
    } catch (e) {
      print('Error registering FCM token: $e');
      return {"success": false, "message": "Terjadi kesalahan koneksi: $e"};
    }
  }

  /// Metode untuk mengambil riwayat presensi siswa.
/// Metode untuk mengambil riwayat presensi siswa.
Future<List<Kehadiran>> getRiwayatPresensi(
  String nis, {
  int? bulan,
  int? tahun,
  int? limit,
}) async {
  Uri url = Uri.parse('$_baseUrl/presensi/riwayat.php');
  Map<String, String> queryParams = {'nis': nis};
  if (bulan != null) queryParams['bulan'] = bulan.toString();
  if (tahun != null) queryParams['tahun'] = tahun.toString();
  if (limit != null) queryParams['limit'] = limit.toString();
  url = url.replace(queryParameters: queryParams);
  
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] is List) {
        List<dynamic> kehadiranJson = responseData['data'];
        List<Kehadiran> parsedKehadiran = [];
        
        // Menggunakan for-loop untuk penanganan error per item
        for (var jsonItem in kehadiranJson) {
          try {
            // Pastikan item yang diproses adalah Map
            if (jsonItem is Map<String, dynamic>) {
              parsedKehadiran.add(Kehadiran.fromJson(jsonItem));
            } else {
              print('Warning: Skipping invalid data format. Expected Map<String, dynamic>, but got ${jsonItem.runtimeType}');
            }
          } catch (e) {
            // Tangani error jika konversi dari Map ke Kehadiran gagal
            print('Error parsing single Kehadiran item: $jsonItem, Error: $e');
          }
        }
        return parsedKehadiran;
      } else {
        print('API Error (getRiwayatPresensi): ${responseData['message'] ?? 'Data tidak valid atau kosong.'}');
        return [];
      }
    } else {
      print('HTTP Error (getRiwayatPresensi): ${response.statusCode} - ${response.body}');
      throw Exception('Server error: ${response.statusCode}');
    }
  } catch (e) {
    print('Catch Error during getRiwayatPresensi: $e');
    throw Exception('Terjadi kesalahan koneksi atau parsing: $e');
  }
}

  /// Metode untuk mengambil riwayat kehadiran guru.
  Future<List<KehadiranGuru>> getRiwayatKehadiranGuru(
    String nipy, {
    int? bulan,
    int? tahun,
    int? limit,
  }) async {
    Uri url = Uri.parse('$_baseUrl/presensi/riwayat_guru.php');
    Map<String, String> queryParams = {'nipy': nipy};
    if (bulan != null) queryParams['bulan'] = bulan.toString();
    if (tahun != null) queryParams['tahun'] = tahun.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    url = url.replace(queryParameters: queryParams);
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] is List) {
          List<dynamic> kehadiranJson = responseData['data'];
          return kehadiranJson.map((json) => KehadiranGuru.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          print('API Error (getRiwayatKehadiranGuru - backend): ${responseData['message'] ?? 'Data tidak valid atau kosong.'}');
          return [];
        }
      } else {
        print('HTTP Error (getRiwayatKehadiranGuru): ${response.statusCode} - ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Catch Error during getRiwayatKehadiranGuru: $e');
      throw Exception('Terjadi kesalahan koneksi atau parsing: $e');
    }
  }

  /// Mengambil daftar catatan siswa (opsional: berdasarkan NIS).
  Future<List<Catatan>> getCatatanList({String? nis}) async {
    Uri url;
    if (nis != null && nis.isNotEmpty) {
      url = Uri.parse('$_baseUrl/catatan/get_catatan_by_nis.php?nis=$nis');
    } else {
      url = Uri.parse('$_baseUrl/catatan/get_all_catatan.php');
    }
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] is List) {
          List<dynamic> catatanJsonList = responseData['data'];
          return catatanJsonList.map((json) => Catatan.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          print('API Error (getCatatanList): ${responseData['message'] ?? 'Data tidak valid atau kosong.'}');
          return [];
        }
      } else {
        print('HTTP Error (getCatatanList): ${response.statusCode} - ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Catch Error during getCatatanList: $e');
      throw Exception('Terjadi kesalahan koneksi atau parsing: $e');
    }
  }

  /// Mengambil catatan siswa tunggal (berdasarkan NIS & tanggal).
  Future<Catatan?> getCatatan(String nis, String tanggalCatatan) async {
    final url = Uri.parse('$_baseUrl/catatan/get_catatan.php?nis=$nis&tanggal=$tanggalCatatan');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          if (data is List && data.isNotEmpty) {
            return Catatan.fromJson(data[0] as Map<String, dynamic>);
          } else if (data is Map) {
            return Catatan.fromJson(data as Map<String, dynamic>);
          }
        }
        return null;
      } else {
        print('HTTP Error (getCatatan): ${response.statusCode}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during getCatatan: $e');
      throw Exception('Terjadi kesalahan koneksi atau parsing: $e');
    }
  }
  
  /// Metode untuk mengambil catatan guru (berdasarkan NIPY).
  Future<List<CatatanGuru>> getCatatanGuruList(String nipy, String formattedDate) async {
    final url = Uri.parse('$_baseUrl/catatan_guru/get_by_nipy.php?nipy=$nipy');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] is List) {
          List<dynamic> catatanJsonList = responseData['data'];
          return catatanJsonList.map((json) => CatatanGuru.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          print('API Error (getCatatanGuru): ${responseData['message'] ?? 'Data tidak valid atau kosong.'}');
          return [];
        }
      } else {
        print('HTTP Error (getCatatanGuru): ${response.statusCode} - ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Catch Error during getCatatanGuru: $e');
      throw Exception('Terjadi kesalahan koneksi atau parsing: $e');
    }
  }

  /// Mengambil catatan guru tunggal (berdasarkan NIPY & tanggal).
  Future<Catatan?> getCatatanGuru(String nipy, String tanggalCatatan) async {
    final url = Uri.parse('$_baseUrl/catatan_guru/get_catatan.php?nipy=$nipy&tanggal=$tanggalCatatan');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          if (data is List && data.isNotEmpty) {
            return Catatan.fromJson(data[0] as Map<String, dynamic>);
          } else if (data is Map) {
            return Catatan.fromJson(data as Map<String, dynamic>);
          }
        }
        return null;
      } else {
        print('HTTP Error (getCatatan): ${response.statusCode}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during getCatatan: $e');
      throw Exception('Terjadi kesalahan koneksi atau parsing: $e');
    }
  }
  
  /// Metode untuk menambah atau memperbarui catatan guru.
  Future<Map<String, dynamic>> addOrUpdateCatatanGuru(CatatanGuru catatanguru) async {
    final url = Uri.parse('$_baseUrl/catatan_guru/add_or_update_catatan.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(catatanguru.toJson()),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true) {
          return {'success': true, 'message': responseData['message']};
        } else {
          return {'success': false, 'message': responseData['message'] ?? 'Gagal menyimpan catatan.'};
        }
      } else {
        print('HTTP Error (addOrUpdateCatatanGuru): ${response.statusCode} - ${response.body}');
        return {'success': false, 'message': 'Server error: ${response.statusCode} - ${response.body}'};
      }
    } catch (e) {
      print('Error during addOrUpdateCatatanGuru: $e');
      return {'success': false, 'message': 'Terjadi kesalahan jaringan atau server: $e'};
    }
  }

  /// Menambah atau memperbarui catatan siswa.
  Future<Map<String, dynamic>> addOrUpdateCatatan(Catatan catatan) async {
    final url = Uri.parse('$_baseUrl/catatan/add_or_update_catatan.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(catatan.toJson()),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true) {
          return {'success': true, 'message': responseData['message']};
        } else {
          return {'success': false, 'message': responseData['message'] ?? 'Gagal menyimpan catatan.'};
        }
      } else {
        print('HTTP Error (addOrUpdateCatatan): ${response.statusCode} - ${response.body}');
        return {'success': false, 'message': 'Server error: ${response.statusCode} - ${response.body}'};
      }
    } catch (e) {
      print('Error during addOrUpdateCatatan: $e');
      return {'success': false, 'message': 'Terjadi kesalahan jaringan atau server: $e'};
    }
  }

  /// Menghapus catatan.
  Future<Map<String, dynamic>> deleteCatatan(String nis, String tanggalCatatan) async {
    final url = Uri.parse('$_baseUrl/catatan/delete_catatan.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nis': nis, 'tanggal_catatan': tanggalCatatan}),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true) {
          return {'success': true, 'message': responseData['message']};
        } else {
          return {'success': false, 'message': responseData['message'] ?? 'Gagal menghapus catatan.'};
        }
      } else {
        return {'success': false, 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      print('Error during deleteCatatan: $e');
      return {'success': false, 'message': 'Terjadi kesalahan jaringan atau server.'};
    }
  }
  
  /// Menghapus catatan guru.
  Future<Map<String, dynamic>> deleteCatatanGuru(String nipy, String tanggalCatatan) async {
    final url = Uri.parse('$_baseUrl/catatan_guru/delete_catatan.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nipy': nipy, 'tanggal_catatan': tanggalCatatan}),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true) {
          return {'success': true, 'message': responseData['message']};
        } else {
          return {'success': false, 'message': responseData['message'] ?? 'Gagal menghapus catatan guru.'};
        }
      } else {
        return {'success': false, 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      print('Error during deleteCatatanGuru: $e');
      return {'success': false, 'message': 'Terjadi kesalahan jaringan atau server.'};
    }
  }

  /// Metode untuk mengambil statistik catatan.
  Future<Map<String, dynamic>> getCatatanStatistics(String nis) async {
    final url = Uri.parse('$_baseUrl/catatan/get_catatan_stats.php?nis=$nis');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true) {
          return responseData['data'] as Map<String, dynamic>;
        } else {
          throw Exception(responseData['message'] ?? 'Gagal mengambil statistik catatan.');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi atau parsing: $e');
    }
  }

  /// Metode untuk mengambil statistik catatan guru.
  Future<Map<String, dynamic>> getCatatanGuruStatistics(String nipy) async {
    final url = Uri.parse('$_baseUrl/catatan_guru/get_catatan_stats.php?nipy=$nipy');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true) {
          return responseData['data'] as Map<String, dynamic>;
        } else {
          throw Exception(responseData['message'] ?? 'Gagal mengambil statistik catatan guru.');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan koneksi atau parsing: $e');
    }
  }

  /// Mengambil data kelas berdasarkan NIPY guru.
  /// Mengembalikan objek Kelas jika ditemukan, atau null jika tidak.
  Future<Kelas?> getKelasByNipy(String nipy) async {
    final url = Uri.parse('$_baseUrl/presensi/get_kelas_by_nipy.php?nipy=$nipy');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] != null) {
          return Kelas.fromJson(responseData['data'] as Map<String, dynamic>);
        }
        return null;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during getKelasByNipy: $e');
      throw Exception('Terjadi kesalahan koneksi atau parsing: $e');
    }
  }

  /// Mengambil daftar siswa berdasarkan nama kelas.
  Future<List<Siswa>> getSiswaByKelas(String namaKelas) async {
    final url = Uri.parse('$_baseUrl/presensi/get_by_kelas.php?kelas=$namaKelas');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] is List) {
          List<dynamic> siswaJsonList = responseData['data'];
          return siswaJsonList.map((json) => Siswa.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          print('API Error (getSiswaByKelas): ${responseData['message'] ?? 'Data tidak valid atau kosong.'}');
          return [];
        }
      } else {
        print('HTTP Error (getSiswaByKelas): ${response.statusCode} - ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Catch Error during getSiswaByKelas: $e');
      throw Exception('Terjadi kesalahan koneksi atau parsing: $e');
    }
  }

  /// MENGAMBIL NIS SISWA YANG SUDAH PRESENSI HARI INI
  /// Sesuai permintaan kelas_screen, fungsi ini sekarang mengembalikan list
  /// objek Kehadiran, bukan hanya string NIS.
  Future<List<Kehadiran>> getKehadiranSiswaForToday(String namaKelas, DateTime selectedDate) async {
    // Format tanggal sesuai kebutuhan backend (YYYY-MM-DD)
    final String tanggal = "${selectedDate.year.toString().padLeft(4, '0')}-"
        "${selectedDate.month.toString().padLeft(2, '0')}-"
        "${selectedDate.day.toString().padLeft(2, '0')}";

    final url = Uri.parse(
      '$_baseUrl/presensi/get_kehadiran_today_by_kelas.php?kelas=$namaKelas&tanggal=$tanggal'
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] is List) {
          List<dynamic> dataList = responseData['data'];
          return dataList.map((item) => Kehadiran.fromJson(item as Map<String, dynamic>)).toList();
        } else {
          print('API Error (getKehadiranSiswaForToday): ${responseData['message'] ?? 'Data tidak valid atau kosong.'}');
          return [];
        }
      } else {
        print('HTTP Error (getKehadiranSiswaForToday): ${response.statusCode} - ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Catch Error during getKehadiranSiswaForToday: $e');
      throw Exception('Terjadi kesalahan koneksi atau parsing: $e');
    }
  }


  /// Metode logout.
  Future<void> logout() async {
    print('Logout API method called.');
  }

  /// Metode untuk mengambil rekap bulanan siswa.
  Future<List<RekapBulananSiswa>> getRekapBulananSiswa(String nis, int tahunMulai) async {
    final url = Uri.parse('$_baseUrl/presensi/get_rekap_bulanan_siswa.php?nis=$nis&tahun_mulai=$tahunMulai');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        if (responseData['success'] == true && responseData['data'] is List) {
          List<dynamic> rekapJsonList = responseData['data'];
          return rekapJsonList.map((json) => RekapBulananSiswa.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          print('API Error (getRekapBulananSiswa): ${responseData['message'] ?? 'Data tidak valid atau kosong.'}');
          return [];
        }
      } else {
        print('HTTP Error (getRekapBulananSiswa): ${response.statusCode} - ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Catch Error during getRekapBulananSiswa: $e');
      throw Exception('Terjadi kesalahan koneksi atau parsing: $e');
    }
  }

  /// Metode untuk menyimpan ketidakhadiran siswa.
  Future<bool> simpanKetidakhadiran(String nis, String keterangan, DateTime tanggal) async {
    final url = Uri.parse('$_baseUrl/presensi/simpan_ketidakhadiran.php');
    final response = await http.post(url, body: {
      'nis': nis,
      'keterangan': keterangan,
      'tanggal': DateFormat('yyyy-MM-dd').format(tanggal),
    });
    final data = jsonDecode(response.body);
    return data['success'] == true;
  }

  /// Metode untuk mengecek apakah siswa sudah memiliki catatan ketidakhadiran di tanggal tertentu.
  Future<bool> cekKetidakhadiran(String nis, DateTime tanggal) async {
    final url = Uri.parse('$_baseUrl/presensi/cek_ketidakhadiran.php?nis=$nis&tanggal=${DateFormat('yyyy-MM-dd').format(tanggal)}');
    final response = await http.get(url);
    final data = jsonDecode(response.body);
    return data['ada'] == true;
  }

  Future<bool> ubahKetidakhadiran(String nis, String keterangan, DateTime tanggal) async {
    final url = Uri.parse('$_baseUrl/presensi/ubah_ketidakhadiran.php');
    final response = await http.post(url, body: {
      'nis': nis,
      'keterangan': keterangan,
      'tanggal': DateFormat('yyyy-MM-dd').format(tanggal),
    });
    final data = jsonDecode(response.body);
    return data['success'] == true;
  }

  Future<bool> hapusKetidakhadiran(String nis, DateTime tanggal) async {
    final url = Uri.parse('$_baseUrl/presensi/hapus_ketidakhadiran.php');
    final response = await http.post(url, body: {
      'nis': nis,
      'tanggal': DateFormat('yyyy-MM-dd').format(tanggal),
    });
    final data = jsonDecode(response.body);
    return data['success'] == true;
  }

  Future<bool> hapusKehadiran(String nis, DateTime tanggal) async {
    final url = Uri.parse('$_baseUrl/presensi/hapus_kehadiran.php');
    final response = await http.post(url, body: {
      'nis': nis,
      'tanggal': DateFormat('yyyy-MM-dd').format(tanggal),
    });
    final data = jsonDecode(response.body);
    return data['success'] == true;
  }

  Future<Map<String, dynamic>> cekKetidakhadiranWithKeterangan(String nis, DateTime tanggal) async {
  final url = Uri.parse('$_baseUrl/kehadiran/cek_ketidakhadiran.php?nis=$nis&tanggal=${DateFormat('yyyy-MM-dd').format(tanggal)}');
  final response = await http.get(url);
  final data = jsonDecode(response.body);
  return {
    'ada': data['ada'] == true,
    'keterangan': data['keterangan'] ?? '',
  };
}

Future<Map<String, int>> getRekapKetidakhadiran(String kelas, DateTime tanggal) async {
  final url = Uri.parse('$_baseUrl/presensi/rekap_ketidakhadiran.php?kelas=$kelas&tanggal=${DateFormat('yyyy-MM-dd').format(tanggal)}');
  final response = await http.get(url);
  final data = jsonDecode(response.body);
  return {
    'sakit': data['sakit'] ?? 0,
    'izin': data['izin'] ?? 0,
    'tanpa_keterangan': data['tanpa_keterangan'] ?? 0,
  };
}

Future<List<Map<String, dynamic>>> getRekapKetidakhadiranBulanan(String nis, int tahunMulai) async {
  final url = Uri.parse('$_baseUrl/presensi/rekap_ketidakhadiran_bulanan.php?nis=$nis&tahun=$tahunMulai');
  final response = await http.get(url);
  final data = jsonDecode(response.body) as List;
  return data.map((e) => Map<String, dynamic>.from(e)).toList();
}

}

