
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/api_service.dart';
import '../models/jadwal.dart';
// import '../models/catatan.dart'; // Catatan tidak lagi digunakan di sini
//import '../utils/auth_manager.dart';

class JadwalScreen extends StatefulWidget {
  const JadwalScreen({super.key});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Jadwal>> _jadwalFuture;
  // String? _currentNis; // Tidak perlu lagi untuk fitur catatan

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _jadwalFuture = _apiService.getJadwal();
    // _initializeUserData(); // Tidak perlu lagi
  }

  // Metode untuk menginisialisasi NIS (sudah tidak diperlukan di sini)
  // Future<void> _initializeUserData() async {
  //   _currentNis = await AuthManager.getUserNis();
  //   if (_currentNis == null) {
  //     print("JadwalScreen: NIS siswa tidak ditemukan. Tidak bisa memuat catatan.");
  //   }
  // }

  // Metode untuk menambah atau memperbarui catatan harian (dihapus dari UI)
  // Future<void> _addOrUpdateCatatan(String catatanText, String tanggalCatatan) async {
  //   if (_currentNis == null) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Gagal menyimpan catatan: NIS tidak ditemukan.')),
  //       );
  //     }
  //     return;
  //   }

  //   Catatan? existingCatatan;
  //   try {
  //     existingCatatan = await _apiService.getCatatan(_currentNis!, tanggalCatatan);
  //   } catch (e) {
  //     existingCatatan = null;
  //   }

  //   final catatanToSave = Catatan(
  //     id: existingCatatan?.id,
  //     nis: _currentNis!,
  //     tanggalCatatan: tanggalCatatan,
  //     catatanText: catatanText,
  //   );

  //   try {
  //     final response = await _apiService.addOrUpdateCatatan(catatanToSave);
  //     if (response['success']) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text(response['message'])),
  //         );
  //       }
  //     } else {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('Gagal menyimpan catatan: ${response['message']}')),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Gagal menyimpan catatan: Terjadi kesalahan jaringan/server')),
  //       );
  //     }
  //   }
  // }

  // Metode untuk menghapus catatan harian (dihapus dari UI)
  // Future<void> _deleteCatatan(String tanggalCatatan) async {
  //   if (_currentNis == null) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Tidak ada catatan untuk dihapus.')),
  //       );
  //     }
  //     return;
  //   }

  //   final confirmDelete = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Hapus Catatan?'),
  //       content: const Text('Apakah Anda yakin ingin menghapus catatan ini?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(false),
  //           child: const Text('Batal'),
  //         ),
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(true),
  //           child: const Text('Hapus', style: TextStyle(color: Colors.red)),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (confirmDelete == true) {
  //     try {
  //       final response = await _apiService.deleteCatatan(_currentNis!, tanggalCatatan);
  //       if (response['success']) {
  //         if (mounted) {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(content: Text(response['message'])),
  //           );
  //           setState(() {});
  //         }
  //       } else {
  //         if (mounted) {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(content: Text('Gagal menghapus catatan: ${response['message']}')),
  //           );
  //         }
  //       }
  //     } catch (e) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text('Gagal menghapus catatan: Terjadi kesalahan jaringan/server')),
  //         );
  //       }
  //     }
  //   }
  // }

  // Metode untuk menampilkan dialog tambah/ubah catatan (dihapus dari UI)
  // void _showNoteDialog(BuildContext context, Jadwal jadwal) async {
  //   if (_currentNis == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Mohon login terlebih dahulu untuk menambah catatan.')),
  //     );
  //     return;
  //   }

  //   Catatan? catatanForDay;
  //   try {
  //     catatanForDay = await _apiService.getCatatan(_currentNis!, jadwal.hari);
  //   } catch (e) {
  //     catatanForDay = null;
  //   }

  //   final TextEditingController noteController = TextEditingController(text: catatanForDay?.catatanText);

  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: Text(
  //           catatanForDay == null ? 'Tambah Catatan' : 'Ubah Catatan',
  //           style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
  //         ),
  //         content: TextField(
  //           controller: noteController,
  //           maxLines: 5,
  //           decoration: InputDecoration(
  //             hintText: 'Tulis catatan Anda di sini...',
  //             border: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(10),
  //             ),
  //           ),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //             child: const Text('Batal'),
  //           ),
  //           if (catatanForDay != null)
  //             TextButton(
  //               onPressed: () {
  //                 Navigator.of(context).pop();
  //                 _deleteCatatan(jadwal.hari);
  //               },
  //               style: TextButton.styleFrom(foregroundColor: Colors.red),
  //               child: const Text('Hapus'),
  //             ),
  //           ElevatedButton(
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               _addOrUpdateCatatan(noteController.text, jadwal.hari);
  //             },
  //             child: Text(catatanForDay == null ? 'Simpan' : 'Perbarui'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // Metode untuk mendapatkan nama hari saat ini dalam bahasa Indonesia
  String _getTodayNameId() {
    final now = DateTime.now();
    final formatter = DateFormat('EEEE', 'id_ID');
    return formatter.format(now);
  }

  // Metode untuk menentukan warna gradient berdasarkan hari
  Color _getCardColorForDay(String dayName, String todayName) {
    if (dayName.toLowerCase() == todayName.toLowerCase()) {
      return Colors.red.shade100; // Warna pastel merah untuk hari ini
    }
    return Colors.blue.shade100; // Warna pastel biru untuk hari lainnya
  }

  @override
  Widget build(BuildContext context) {
    final todayName = _getTodayNameId();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Jadwal',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F7FA),
              Colors.white,
            ],
          ),
        ),
        child: FutureBuilder<List<Jadwal>>(
          future: _jadwalFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'Tidak ada jadwal pelajaran.',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              );
            } else {
              final jadwalList = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: jadwalList.length,
                itemBuilder: (context, index) {
                  final jadwal = jadwalList[index];
                  final cardColor = _getCardColorForDay(jadwal.namaHari, todayName);

                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: cardColor == Colors.blue.shade100 ? 4 : 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: cardColor == Colors.blue.shade100 ? Colors.blue.shade200 : Colors.red.shade200,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                jadwal.namaHari,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: cardColor == Colors.blue.shade100 ? Colors.blueAccent : Colors.red.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${jadwal.jamMasuk} - ${jadwal.jamPulang}',
                                    style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Tombol catatan (sekarang sudah dihapus)
                          // IconButton(
                          //   icon: const Icon(Icons.edit_note, color: Colors.deepPurple),
                          //   onPressed: () => _showNoteDialog(context, jadwal),
                          //   tooltip: 'Tambah/Ubah Catatan',
                          // ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}