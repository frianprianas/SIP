import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/siswa.dart';
import '../models/rekap_bulanan_siswa.dart'; // Buat model ini sesuai jawaban sebelumnya

class RekapPresensiScreen extends StatefulWidget {
  final String namaKelas;
  const RekapPresensiScreen({super.key, required this.namaKelas});

  @override
  State<RekapPresensiScreen> createState() => _RekapPresensiScreenState();
}

class _RekapPresensiScreenState extends State<RekapPresensiScreen> {
  final ApiService _apiService = ApiService();
  List<Siswa> _siswaList = [];
  bool _isLoadingSiswa = true;

  @override
  void initState() {
    super.initState();
    _fetchSiswa();
  }

  Future<void> _fetchSiswa() async {
    try {
      final siswaList = await _apiService.getSiswaByKelas(widget.namaKelas);
      setState(() {
        _siswaList = siswaList;
        _isLoadingSiswa = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSiswa = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar siswa')),
      );
    }
  }

  Future<void> _showRekapModal(BuildContext context, Siswa siswa) async {
    final now = DateTime.now();
    int tahunMulai = now.month >= 7 ? now.year : now.year - 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FutureBuilder<List<dynamic>>(
          future: Future.wait([
            _apiService.getRekapBulananSiswa(siswa.nis, tahunMulai), // List<RekapBulananSiswa>
            _apiService.getRekapKetidakhadiranBulanan(siswa.nis, tahunMulai), // List<Map<String, dynamic>>
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 350,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return SizedBox(
                height: 350,
                child: Center(child: Text('Gagal memuat data rekap')),
              );
            }
            final List<RekapBulananSiswa> rekapPresensi = snapshot.data![0] as List<RekapBulananSiswa>;
            final List<Map<String, dynamic>> rekapKetidakhadiran = snapshot.data![1] as List<Map<String, dynamic>>;

            // Gabungkan data berdasarkan bulan
            List<Map<String, dynamic>> rekapGabungan = [];
            for (int i = 0; i < rekapPresensi.length; i++) {
              final presensi = rekapPresensi[i];
              final ketidakhadiran = rekapKetidakhadiran.length > i ? rekapKetidakhadiran[i] : {};
              rekapGabungan.add({
                'bulan': presensi.bulan,
                'hari_aktif': presensi.hariAktif,
                'hadir': presensi.jumlahHadir,
                'izin': ketidakhadiran['izin'] ?? 0,
                'sakit': ketidakhadiran['sakit'] ?? 0,
                'absen': ketidakhadiran['absen'] ?? 0,
              });
            }

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rekap Kehadiran Bulanan\n${siswa.nama}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 320,
                    child: ListView.builder(
                      itemCount: rekapGabungan.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Container(
                            color: Colors.blue.shade50,
                            child: Row(
                              children: [
                                Expanded(child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Bulan/Tahun', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                )),
                                Expanded(child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Hari Aktif', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                )),
                                Expanded(child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Hadir', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                )),
                                Expanded(child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Izin', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                )),
                                Expanded(child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Sakit', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                )),
                                Expanded(child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Absen', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                )),
                              ],
                            ),
                          );
                        }
                        final rekap = rekapGabungan[index - 1];
                        return Row(
                          children: [
                            Expanded(child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(rekap['bulan'], style: GoogleFonts.poppins()),
                            )),
                            Expanded(child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('${rekap['hari_aktif']}', style: GoogleFonts.poppins()),
                            )),
                            Expanded(child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('${rekap['hadir']}', style: GoogleFonts.poppins()),
                            )),
                            Expanded(child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('${rekap['izin']}', style: GoogleFonts.poppins()),
                            )),
                            Expanded(child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('${rekap['sakit']}', style: GoogleFonts.poppins()),
                            )),
                            Expanded(child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('${rekap['absen']}', style: GoogleFonts.poppins()),
                            )),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.keyboard_arrow_down, color: Colors.blueAccent, size: 28),
                  Text(
                    'Scroll untuk melihat semua bulan',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.blueAccent),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rekap Presensi ${widget.namaKelas}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF87CEEB),
              Color(0xFFADD8E6),
              Colors.white,
              Colors.white,
            ],
            stops: [0.1, 0.4, 0.8, 1.0],
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Icon(Icons.person_search, size: 40, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Pilih Siswa',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Ganti SizedBox dengan Expanded agar ListView builder fleksibel
                  Expanded(
                    child: _isLoadingSiswa
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            itemCount: _siswaList.length,
                            itemBuilder: (context, index) {
                              final siswa = _siswaList[index];
                              return Card(
                                color: Colors.white,
                                elevation: 1,
                                child: ListTile(
                                  title: Text(
                                    siswa.nama,
                                    style: GoogleFonts.poppins(fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.info_outline, color: Colors.blueAccent),
                                    tooltip: 'Lihat Rekap Bulanan',
                                    onPressed: () => _showRekapModal(context, siswa),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Tap ikon detail untuk melihat rekap bulanan',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}