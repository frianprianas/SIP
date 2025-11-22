import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/kehadiran.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class RiwayatPresensiScreen extends StatefulWidget {
  final String nis;

  const RiwayatPresensiScreen({super.key, required this.nis});

  @override
  State<RiwayatPresensiScreen> createState() => _RiwayatPresensiScreenState();
}

class _RiwayatPresensiScreenState extends State<RiwayatPresensiScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController(); // Tambahkan ini

  int? _selectedMonth;
  int? _selectedYear;

  final List<Map<String, dynamic>> _months = [
    {'id': null, 'name': 'Semua Bulan'},
    for (int i = 1; i <= 12; i++) {'id': i, 'name': _getMonthName(i)},
  ];

  final List<int?> _years = [
    null,
    for (int i = DateTime.now().year + 1; i >= DateTime.now().year - 5; i--) i,
  ];

  late Future<List<Kehadiran>> _futureRiwayatPresensi;

  static String _getMonthName(int month) {
    const List<String> monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return monthNames[month - 1];
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _futureRiwayatPresensi = _fetchRiwayatPresensi();
  }

  Future<List<Kehadiran>> _fetchRiwayatPresensi() {
    return _apiService.getRiwayatPresensi(
      widget.nis,
      bulan: _selectedMonth,
      tahun: _selectedYear,
    );
  }

  void _showFotoModal(BuildContext context, int idKehadiran) {
    final String fotoFileName = '$idKehadiran.jpg';
    final String fotoUrl = '${AppConstants.fotoBaseUrl}/$fotoFileName';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 3,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    fotoUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 250,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 250,
                        color: Colors.grey[200],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_outlined, size: 60, color: Colors.grey[500]),
                              const SizedBox(height: 10),
                              Text(
                                'Foto tidak ditemukan',
                                style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: double.infinity,
                        height: 250,
                        color: Colors.grey[100],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Detail Foto Kehadiran',
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'ID Kehadiran: $idKehadiran',
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        ),
                        child: Text(
                          'Tutup',
                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(String dateTimeString) {
    try {
      DateTime dt = DateTime.parse(dateTimeString);
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error parsing date time: $e for string: $dateTimeString');
      return 'Invalid Date/Time';
    }
  }

  // Metode baru untuk mendapatkan jumlah hari kerja (Senin-Jumat) dalam bulan yang dipilih
  int _getWorkingDaysInMonth(int year, int month) {
    int workingDays = 0;
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);

    for (int i = 0; i <= lastDayOfMonth.day - firstDayOfMonth.day; i++) {
      final day = firstDayOfMonth.add(Duration(days: i));
      // Cek apakah hari adalah hari kerja (Senin=1, Selasa=2, ..., Jumat=5)
      if (day.weekday >= DateTime.monday && day.weekday <= DateTime.friday) {
        workingDays++;
      }
    }
    return workingDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: CustomScrollView(
          controller: _scrollController, // Integrasikan controller di sini
          slivers: [
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 16.0),
                title: Text(
                  'Riwayat Presensi',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF3E8BCB),
                        Color(0xFF6DA2D9),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Icon(Icons.history, size: 70, color: Colors.white),
                      const SizedBox(height: 10),
                      Text(
                        'Riwayat Presensi Siswa',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    // Filter Dropdown
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int?>(
                                initialValue: _selectedMonth,
                                decoration: InputDecoration(
                                  labelText: 'Bulan',
                                  labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.blueAccent),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.blue.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  isDense: true,
                                ),
                                items: _months.map((month) {
                                  return DropdownMenuItem<int?>(
                                    value: month['id'] as int?,
                                    child: Text(
                                      month['name'] as String,
                                      style: GoogleFonts.poppins(),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (int? newValue) {
                                  setState(() {
                                    _selectedMonth = newValue;
                                    _futureRiwayatPresensi = _fetchRiwayatPresensi();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: DropdownButtonFormField<int?>(
                                initialValue: _selectedYear,
                                decoration: InputDecoration(
                                  labelText: 'Tahun',
                                  labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.blueAccent),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.blue.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  isDense: true,
                                ),
                                items: _years.map((year) {
                                  return DropdownMenuItem<int?>(
                                    value: year,
                                    child: Text(
                                      year == null ? 'Semua Tahun' : year.toString(),
                                      style: GoogleFonts.poppins(),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (int? newValue) {
                                  setState(() {
                                    _selectedYear = newValue;
                                    _futureRiwayatPresensi = _fetchRiwayatPresensi();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Tombol "Lihat Rekap"
                    GestureDetector(
                      onTap: () {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.summarize, color: Colors.blueAccent, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'Lihat Rekap',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
            FutureBuilder<List<Kehadiran>>(
              future: _futureRiwayatPresensi,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent))));
                } else if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Error memuat riwayat: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.red[700], fontSize: 16),
                        ),
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sentiment_dissatisfied, size: 60, color: Colors.grey[500]),
                            const SizedBox(height: 10),
                            Text(
                              'Tidak ada riwayat presensi ditemukan untuk filter ini.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  // Perhitungan total hari kerja dan jumlah kehadiran
                  final kehadiranList = snapshot.data!;
                  final presentCount = kehadiranList.where((k) => k.status == 'MASUK').length;
                  final totalWorkingDaysInMonth = (_selectedYear != null && _selectedMonth != null)
                      ? _getWorkingDaysInMonth(_selectedYear!, _selectedMonth!)
                      : 0;

                  return SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: kehadiranList.length,
                          itemBuilder: (context, index) {
                            Kehadiran kehadiran = kehadiranList[index];

                            String tanggal = _formatDateTime(kehadiran.waktuTap).split(' ')[0];
                            String jam = _formatDateTime(kehadiran.waktuTap).split(' ')[1];

                            Color statusColor = kehadiran.status == 'MASUK' ? Colors.green[700]! : Colors.red[700]!;
                            Color statusBgColor = kehadiran.status == 'MASUK' ? Colors.green.shade100 : Colors.red.shade100;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              elevation: 6,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tanggal,
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueGrey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          jam,
                                          style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: statusBgColor,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: statusColor, width: 0.5),
                                          ),
                                          child: Text(
                                            kehadiran.status,
                                            style: GoogleFonts.poppins(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        if (kehadiran.id > 0)
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.blue.shade100.withOpacity(0.5),
                                                  spreadRadius: 1,
                                                  blurRadius: 3,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.camera_alt, size: 28),
                                              color: Colors.blueAccent,
                                              onPressed: () => _showFotoModal(context, kehadiran.id),
                                              tooltip: 'Lihat Foto',
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Tambahkan summary di sini
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ringkasan Bulan Ini',
                                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                  ),
                                  const Divider(height: 20, thickness: 1, color: Colors.grey),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Jumlah hari kerja:',
                                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
                                      ),
                                      Text(
                                        '$totalWorkingDaysInMonth hari',
                                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Jumlah kehadiran bulan ini:',
                                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
                                      ),
                                      Text(
                                        '$presentCount hari',
                                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}