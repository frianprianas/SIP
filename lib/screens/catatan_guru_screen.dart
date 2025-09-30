// File: lib/screens/catatan_guru_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/catatan_guru.dart';
import '../services/api_service.dart';

// CatatanGuruScreen adalah StatefulWidget untuk halaman catatan harian guru.
// Menerima parameter `nipy` (Nomor Induk Pegawai Yayasan).
class CatatanGuruScreen extends StatefulWidget {
  final String nipy;
  const CatatanGuruScreen({super.key, required this.nipy});

  @override
  State<CatatanGuruScreen> createState() => _CatatanGuruScreenState();
}

class _CatatanGuruScreenState extends State<CatatanGuruScreen> {
  // Inisialisasi ApiService untuk komunikasi dengan backend.
  final ApiService _apiService = ApiService();
  // Controller untuk mengontrol input pada TextField catatan.
  final TextEditingController _catatanController = TextEditingController();
  // Tanggal yang dipilih oleh pengguna, defaultnya adalah hari ini.
  DateTime _selectedDate = DateTime.now();
  // Status loading untuk menampilkan CircularProgressIndicator.
  bool _isLoading = false;
  // Menyimpan catatan awal dari server untuk membandingkan perubahan.
  String _initialNote = '';

  // Variabel untuk menyimpan jumlah catatan.
  int _totalCatatan = 0;
  int _catatanBulanIni = 0;

  // Tambahkan variabel untuk menyimpan tanggal yang memiliki catatan
  Set<DateTime> _datesWithNotes = {};
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Inisialisasi locale untuk DateFormat
    initializeDateFormatting('id_ID', null);
    // Saat widget pertama kali dibuat, muat catatan untuk tanggal saat ini.
    print('DEBUG: initState() - Memuat catatan untuk tanggal ${_selectedDate.toIso8601String()}');
    _fetchCatatanAndSetState(_selectedDate);
    // Memuat statistik catatan saat pertama kali widget diinisialisasi
    _fetchCatatanStatistics();
    // Ambil daftar tanggal yang punya catatan guru untuk bulan fokus
    _fetchDatesWithNotesGuru(_focusedDay);
  }

  @override
  void dispose() {
    _catatanController.dispose();
    print('DEBUG: dispose() - Controller catatan dibuang.');
    super.dispose();
  }

  // Metode untuk mengambil catatan dari server dan memperbarui state.
  Future<void> _fetchCatatanAndSetState(DateTime date) async {
    if (!mounted) return;
    print('DEBUG: _fetchCatatanAndSetState() dipanggil untuk tanggal ${date.toIso8601String()}');
    setState(() { _isLoading = true; });

    try {
      final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      print('DEBUG: Memulai panggilan API getCatatanGuru untuk NIPY ${widget.nipy} dan tanggal $formattedDate');
      final catatanguru = await _apiService.getCatatanGuru(widget.nipy, formattedDate);

      if (mounted) {
        setState(() {
          print('DEBUG: setState() dipanggil untuk memperbarui catatan dan menonaktifkan loading.');
          if (catatanguru != null) {
            _catatanController.text = catatanguru.catatanText;
            _initialNote = catatanguru.catatanText;
            final preview = _catatanController.text.length > 10
                ? '${_catatanController.text.substring(0, 10)}...'
                : _catatanController.text;
            print('DEBUG: Catatan berhasil dimuat. Teks catatan (preview): $preview');
          } else {
            _catatanController.clear();
            _initialNote = '';
            print('DEBUG: Catatan tidak ditemukan. Teks catatan dikosongkan.');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Catatan tidak ditemukan untuk tanggal ini.',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          _isLoading = false; // Nonaktifkan loading setelah proses selesai
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; }); // Nonaktifkan loading meskipun ada error
        print('DEBUG: Terjadi error saat memuat catatan: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memuat catatan: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Ambil daftar tanggal yang punya catatan guru untuk bulan fokus
  Future<void> _fetchDatesWithNotesGuru(DateTime focusedMonth) async {
    try {
      final year = focusedMonth.year;
      final month = focusedMonth.month;
      print('DEBUG: requesting datesWithNotes for nipy=${widget.nipy} year=$year month=$month');
      final List<String> dates = await _apiService.getDatesWithNotesGuru(widget.nipy, year, month);
      print('DEBUG: received dates: $dates');
      final Set<DateTime> setDates = dates.map((s) {
        final d = DateTime.parse(s);
        return DateTime(d.year, d.month, d.day);
      }).toSet();
      if (mounted) {
        setState(() {
          _datesWithNotes = setDates;
        });
      }
    } catch (e) {
      print('DEBUG: Gagal memuat tanggal berisi catatan guru: $e');
    }
  }

  // Metode untuk mengambil statistik jumlah catatan.
  Future<void> _fetchCatatanStatistics() async {
    if (!mounted) return;
    try {
      print('DEBUG: Memuat statistik catatan guru untuk NIPY: ${widget.nipy}...');
      final Map<String, dynamic> stats = await _apiService.getCatatanGuruStatistics(widget.nipy);
      if (mounted) {
        setState(() {
          _totalCatatan = stats['total'] ?? 0;
          _catatanBulanIni = stats['bulan_ini'] ?? 0;
          print('DEBUG: Statistik catatan berhasil dimuat: Total = $_totalCatatan, Bulan Ini = $_catatanBulanIni');
        });
      }
    } catch (e) {
      print('DEBUG: Gagal memuat statistik catatan: $e');
      if (mounted) {
        // Reset ke 0 jika error
        setState(() {
          _totalCatatan = 0;
          _catatanBulanIni = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memuat statistik: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Metode untuk menambah atau memperbarui catatan.
  Future<void> _addOrUpdateCatatanGuru() async {
    print('DEBUG: _addOrUpdateCatatanGuru() dipanggil.');
    if (_catatanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Catatan tidak boleh kosong.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final CatatanGuru newCatatan = CatatanGuru(
        nipy: widget.nipy,
        tanggalCatatan: formattedDate,
        catatanText: _catatanController.text.trim(),
      );
      
      print('DEBUG: Memulai panggilan API addOrUpdateCatatanGuru.');
      final response = await _apiService.addOrUpdateCatatanGuru(newCatatan);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (response['success'] == true) {
          _initialNote = _catatanController.text.trim();
          print('DEBUG: Catatan berhasil disimpan.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Catatan berhasil disimpan.',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Perbarui statistik setelah menyimpan catatan
          await _fetchCatatanStatistics();
          // Perbarui kalender untuk menampilkan tanggal yang memiliki catatan
          await _fetchDatesWithNotesGuru(_focusedDay);
        } else {
          print('DEBUG: Catatan gagal disimpan. Pesan: ${response['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Gagal menyimpan catatan.',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print('DEBUG: Terjadi error saat menyimpan catatan: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Terjadi kesalahan saat menyimpan: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Metode untuk menghapus catatan.
  Future<void> _deleteCatatan() async {
    print('DEBUG: _deleteCatatan() dipanggil.');
    if (_initialNote.isEmpty && _catatanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak ada catatan untuk dihapus.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      print('DEBUG: Memulai panggilan API deleteCatatanGuru untuk tanggal $formattedDate');
      final response = await _apiService.deleteCatatanGuru(widget.nipy, formattedDate);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (response['success'] == true) {
          _catatanController.clear();
          _initialNote = '';
          print('DEBUG: Catatan berhasil dihapus.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Catatan berhasil dihapus.',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Perbarui statistik setelah menghapus catatan
          await _fetchCatatanStatistics();
          // Perbarui kalender untuk menampilkan tanggal yang memiliki catatan
          await _fetchDatesWithNotesGuru(_focusedDay);
        } else {
          print('DEBUG: Gagal menghapus catatan. Pesan: ${response['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Gagal menghapus catatan.',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print('DEBUG: Terjadi error saat menghapus catatan: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Terjadi kesalahan saat menghapus: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Metode baru untuk menampilkan dialog konfirmasi penghapusan.
  Future<void> _showDeleteConfirmationDialog() async {
    // Tampilkan dialog hanya jika tidak ada catatan kosong
    if (_initialNote.isEmpty && _catatanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak ada catatan untuk dihapus.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Tampilkan dialog konfirmasi
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Hapus Catatan?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus catatan ini?',
            style: GoogleFonts.poppins(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Tutup dialog dan kembalikan nilai false
                Navigator.of(context).pop(false);
              },
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(color: Colors.blue),
              ),
            ),
            TextButton(
              onPressed: () {
                // Tutup dialog dan kembalikan nilai true
                Navigator.of(context).pop(true);
              },
              child: Text(
                'Hapus',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    // Jika pengguna mengkonfirmasi penghapusan, panggil metode _deleteCatatan()
    if (shouldDelete == true) {
      _deleteCatatan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Catatan Harian Guru',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      // Menggunakan Container untuk memberikan latar belakang gradasi
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD), // Biru muda sangat terang
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NIPY: ${widget.nipy}',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              
              // Bagian Card untuk menampilkan statistik
              _buildStatisticsCard(),
              const SizedBox(height: 20),

              // -- Tambahkan Calendar yang menandai tanggal berisi catatan guru --
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  child: SizedBox(
                    height: 360, // pastikan kalender terlihat di SingleChildScrollView
                    child: TableCalendar(
                      firstDay: DateTime.utc(2000, 1, 1),
                      lastDay: DateTime.utc(2100, 12, 31),
                      focusedDay: _focusedDay,
                      locale: 'id_ID',
                      calendarFormat: CalendarFormat.month,
                      selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
                      onDaySelected: (selectedDay, focusedDay) async {
                        if (!isSameDay(_selectedDate, selectedDay)) {
                          setState(() {
                            _selectedDate = selectedDay;
                            _focusedDay = focusedDay;
                            _isLoading = true;
                          });
                          await _fetchCatatanAndSetState(selectedDay);
                          await _fetchDatesWithNotesGuru(focusedDay);
                        }
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                        _fetchDatesWithNotesGuru(focusedDay);
                      },
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          final hasNote = _datesWithNotes.contains(DateTime(day.year, day.month, day.day));
                          if (hasNote) {
                            return Container(
                              margin: const EdgeInsets.all(6.0),
                              decoration: BoxDecoration(
                                color: Colors.lightBlue.shade100,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              alignment: Alignment.center,
                              child: Text('${day.day}', style: const TextStyle(color: Colors.black87)),
                            );
                          }
                          return null;
                        },
                        todayBuilder: (context, day, focusedDay) {
                          final hasNote = _datesWithNotes.contains(DateTime(day.year, day.month, day.day));
                          return Container(
                            margin: const EdgeInsets.all(6.0),
                            decoration: BoxDecoration(
                              color: hasNote ? Colors.lightBlue.shade200 : Colors.blueAccent,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            alignment: Alignment.center,
                            child: Text('${day.day}', style: const TextStyle(color: Colors.white)),
                          );
                        },
                        selectedBuilder: (context, day, focusedDay) {
                          return Container(
                            margin: const EdgeInsets.all(6.0),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            alignment: Alignment.center,
                            child: Text('${day.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_datesWithNotes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    'Tidak ada catatan di bulan ini (debug). Cek console atau endpoint.',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  ),
                ),

              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Tanggal',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today, color: Colors.blueAccent),
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null && picked != _selectedDate) {
                                if (!mounted) return;
                                // Tampilkan dialog konfirmasi
                                await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Lihat Catatan', style: GoogleFonts.poppins()),
                                    content: Text(
                                      'Apakah Anda ingin melihat catatan di tanggal ${DateFormat('d MMMM yyyy', 'id_ID').format(picked)}?',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: Text('Batal', style: GoogleFonts.poppins(color: Colors.red)),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          print('DEBUG: Tombol "Lihat" di dialog ditekan.');
                                          setState(() {
                                            _selectedDate = picked;
                                            _catatanController.clear();
                                            _isLoading = true;
                                            print('DEBUG: setState() dipanggil. _isLoading = true, teks catatan dikosongkan.');
                                          });
                                          Navigator.of(context).pop();
                                          _fetchCatatanAndSetState(picked);
                                        },
                                        child: Text('Lihat', style: GoogleFonts.poppins()),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Catatan Harian',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              
              Stack(
                children: [
                  TextField(
                    controller: _catatanController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'Tulis catatan Anda di sini...',
                      hintStyle: GoogleFonts.poppins(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.blueAccent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                      ),
                    ),
                    readOnly: _isLoading,
                  ),
                  if (_isLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.1),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _addOrUpdateCatatanGuru,
                      icon: const Icon(Icons.save),
                      label: Text('Simpan', style: GoogleFonts.poppins()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _showDeleteConfirmationDialog,
                      icon: const Icon(Icons.delete),
                      label: Text('Hapus', style: GoogleFonts.poppins()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget terpisah untuk membangun card statistik
  Widget _buildStatisticsCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildStatisticRow(
              label: 'Jumlah catatan Anda bulan ini:',
              value: _catatanBulanIni,
            ),
            const Divider(height: 25),
            _buildStatisticRow(
              label: 'Jumlah semua catatan Anda:',
              value: _totalCatatan,
            ),
          ],
        ),
      ),
    );
  }

  // Widget terpisah untuk membuat baris statistik
  Widget _buildStatisticRow({required String label, required int value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.blueGrey,
          ),
        ),
        Text(
          '$value',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
      ],
    );
  }
}