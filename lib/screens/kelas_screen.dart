// File: lib/screens/kelas_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Impor untuk memformat tanggal

import '../models/siswa.dart';
import '../models/kehadiran.dart'; // Menggunakan model kehadiran.dart
import '../services/api_service.dart';

class KelasScreen extends StatefulWidget {
  final String namaKelas;
  const KelasScreen({super.key, required this.namaKelas});

  @override
  State<KelasScreen> createState() => _KelasScreenState();
}

class _KelasScreenState extends State<KelasScreen> {
  final ApiService _apiService = ApiService();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<Kehadiran> _kehadiranList = [];
  List<Siswa> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchStudentsAndKehadiran();
  }

  /// Mengambil data siswa dan kehadiran dari API
  Future<void> _fetchStudentsAndKehadiran() async {
    print('Mulai fetch data...');
    setState(() {
      _isLoading = true;
    });

    try {
      final siswaList = await _apiService.getSiswaByKelas(widget.namaKelas);
      print('Siswa list didapat: ${siswaList.length}');
      final kehadiranList = await _apiService.getKehadiranSiswaForToday(
        widget.namaKelas,
        _selectedDate,
      );
      print('Kehadiran list didapat: ${kehadiranList.length}');
      if (mounted) {
        setState(() {
          _students = siswaList;
          _kehadiranList = kehadiranList;
        });
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data kelas: $e')),
        );
      }
    } finally {
      print('Selesai fetch data');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Membuka dialog pemilih tanggal
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      // locale: const Locale('id', 'ID'), // KOMENTARI/HAPUS BARIS INI DULU
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _fetchStudentsAndKehadiran();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalSiswa = _students.length;
    final int siswaHadir = _kehadiranList.where((k) => k.status.toLowerCase() == 'masuk' || k.status.toLowerCase() == 'hadir').length;
    final int siswaBelumHadir = totalSiswa - siswaHadir;
    final int siswaSakit = _kehadiranList.where((k) => k.status.toLowerCase() == 'sakit').length;
    final int siswaIzin = _kehadiranList.where((k) => k.status.toLowerCase() == 'izin').length;
    final int siswaAbsen = _kehadiranList.where((k) => k.status.toLowerCase() == 'absen' || k.status.toLowerCase() == 'tidak hadir').length;

    final List<Kehadiran> semuaSiswa = List<Kehadiran>.from(_kehadiranList)
      ..sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Kelas ${widget.namaKelas}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Card Statistik Kehadiran dengan desain menyatu
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Kehadiran Tanggal', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.blueAccent, width: 1),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today, color: Colors.blueAccent, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDate),
                                      style: GoogleFonts.poppins(fontSize: 15, color: Colors.blueAccent, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Jumlah Siswa:', style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[700])),
                                Text('$totalSiswa', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Sudah Hadir:', style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[700])),
                                Text('$siswaHadir', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green[700])),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Belum Hadir:', style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[700])),
                                Text('$siswaBelumHadir', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red[700])),
                              ],
                            ),
                            const SizedBox(height: 6),
                            FutureBuilder<Map<String, int>>(
                              future: _apiService.getRekapKetidakhadiran(widget.namaKelas, _selectedDate),
                              builder: (context, snapshot) {
                                final sakit = snapshot.data?['sakit'] ?? 0;
                                final izin = snapshot.data?['izin'] ?? 0;
                                final tanpaKeterangan = snapshot.data?['tanpa_keterangan'] ?? 0;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Sakit:', style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[700])),
                                        Text('$sakit', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Izin:', style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[700])),
                                        Text('$izin', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Tanpa Keterangan:', style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[700])),
                                        Text('$tanpaKeterangan', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Daftar siswa satu kali saja
                    for (var k in semuaSiswa)
                      FutureBuilder<bool>(
                        future: _apiService.cekKetidakhadiran(k.nis, _selectedDate),
                        builder: (context, snapshot) {
                          final sudahIsiKetidakhadiran = snapshot.data == true;
                          final warnaCard = sudahIsiKetidakhadiran
                              ? Colors.grey.shade200
                              : (k.status.toLowerCase() == 'masuk' || k.status.toLowerCase() == 'hadir')
                                  ? Colors.green.shade50
                                  : Colors.red.shade50;
                          return Card(
                            color: warnaCard,
                            child: ListTile(
                              leading: Icon(
                                (k.status.toLowerCase() == 'masuk' || k.status.toLowerCase() == 'hadir')
                                    ? Icons.check_circle
                                    : sudahIsiKetidakhadiran
                                        ? Icons.info_outline
                                        : Icons.cancel,
                                color: (k.status.toLowerCase() == 'masuk' || k.status.toLowerCase() == 'hadir')
                                    ? Colors.green
                                    : sudahIsiKetidakhadiran
                                        ? Colors.grey
                                        : Colors.red,
                              ),
                              title: Text(k.nama, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                              subtitle: Text('NIS: ${k.nis}'),
                              trailing: sudahIsiKetidakhadiran
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit, color: Colors.blueAccent),
                                          tooltip: 'Ubah Keterangan',
                                          onPressed: () async {
                                            // Tampilkan modal edit (mirip input, isi default dari API)
                                            String? selectedKeterangan = await _showEditKetidakhadiranDialog(context, k);
                                            if (selectedKeterangan != null && selectedKeterangan.isNotEmpty) {
                                              final sukses = await _apiService.ubahKetidakhadiran(k.nis, selectedKeterangan, _selectedDate);
                                              if (sukses) setState(() {});
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, color: Colors.redAccent),
                                          tooltip: 'Hapus Ketidakhadiran',
                                          onPressed: () async {
                                            final konfirmasi = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text('Hapus Data?', style: GoogleFonts.poppins()),
                                                content: Text('Yakin ingin menghapus data ketidakhadiran?', style: GoogleFonts.poppins()),
                                                actions: [
                                                  TextButton(child: Text('Batal'), onPressed: () => Navigator.pop(context, false)),
                                                  ElevatedButton(child: Text('Hapus'), onPressed: () => Navigator.pop(context, true)),
                                                ],
                                              ),
                                            );
                                            if (konfirmasi == true) {
                                              final sukses = await _apiService.hapusKetidakhadiran(k.nis, _selectedDate);
                                              if (sukses) setState(() {});
                                            }
                                          },
                                        ),
                                      ],
                                    )
                                  : Text(
                                      (k.status.toLowerCase() == 'masuk' || k.status.toLowerCase() == 'hadir')
                                          ? 'Hadir'
                                          : 'Absen',
                                      style: GoogleFonts.poppins(
                                        color: (k.status.toLowerCase() == 'masuk' || k.status.toLowerCase() == 'hadir')
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                              onTap: (!sudahIsiKetidakhadiran && !(k.status.toLowerCase() == 'masuk' || k.status.toLowerCase() == 'hadir'))
                                  ? () async {
                                      String? selectedKeterangan;
                                      final hasil = await showDialog<String>(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: Center(child: Text('Input Ketidakhadiran', style: GoogleFonts.poppins(fontWeight: FontWeight.bold))),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('Nama: ${k.nama}', style: GoogleFonts.poppins(fontSize: 15)),
                                                Text('NIS: ${k.nis}', style: GoogleFonts.poppins(fontSize: 15)),
                                                const SizedBox(height: 16),
                                                DropdownButtonFormField<String>(
                                                  decoration: InputDecoration(
                                                    labelText: 'Keterangan',
                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  items: ['Absen', 'Sakit', 'Izin'].map((opt) => DropdownMenuItem(
                                                    value: opt,
                                                    child: Text(opt, style: GoogleFonts.poppins()),
                                                  )).toList(),
                                                  onChanged: (val) => selectedKeterangan = val,
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text('Batal', style: GoogleFonts.poppins()),
                                                onPressed: () => Navigator.pop(context),
                                              ),
                                              ElevatedButton(
                                                child: Text('Simpan', style: GoogleFonts.poppins()),
                                                onPressed: () {
                                                  Navigator.pop(context, selectedKeterangan);
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      if (hasil != null && hasil.isNotEmpty) {
                                        final sukses = await _apiService.simpanKetidakhadiran(k.nis, hasil, _selectedDate);
                                        if (sukses) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Berhasil disimpan!')),
                                          );
                                          setState(() {}); // Refresh tampilan
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Gagal menyimpan!')),
                                          );
                                        }
                                      }
                                    }
                                  : null,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Widget pembantu untuk menampilkan baris statistik.
  Widget _buildStatistikRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.blueGrey[800],
            ),
          ),
        ],
      ),
    );
  }

  /// Menampilkan dialog untuk mengedit keterangan ketidakhadiran
  Future<String?> _showEditKetidakhadiranDialog(BuildContext context, Kehadiran kehadiran) async {
    final List<String> pilihan = ['Absen', 'Sakit', 'Izin'];
    String? selectedKeterangan = pilihan.contains(kehadiran.status) ? kehadiran.status : null;
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Center(child: Text('Ubah Keterangan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nama: ${kehadiran.nama}', style: GoogleFonts.poppins(fontSize: 15)),
              Text('NIS: ${kehadiran.nis}', style: GoogleFonts.poppins(fontSize: 15)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Keterangan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                value: selectedKeterangan,
                items: pilihan.map((opt) => DropdownMenuItem(
                  value: opt,
                  child: Text(opt, style: GoogleFonts.poppins()),
                )).toList(),
                onChanged: (val) => selectedKeterangan = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Batal', style: GoogleFonts.poppins()),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('Simpan', style: GoogleFonts.poppins()),
              onPressed: () {
                Navigator.pop(context, selectedKeterangan);
              },
            ),
          ],
        );
      },
    );
  }
}
