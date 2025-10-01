// File: lib/screens/dashboard_guru_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/guru.dart';
import '../models/kehadiran_guru.dart'; // Menggunakan model kehadiran guru
import '../models/kelas.dart'; // Impor model Kelas yang baru
import '../services/api_service.dart';
import '../utils/auth_manager.dart';
import 'login_screen.dart';
import 'jadwal_screen.dart'; // Asumsi JadwalScreen dapat digunakan oleh guru dan siswa
import 'riwayat_kehadiran_guru_screen.dart'; // Halaman baru untuk riwayat kehadiran guru
import 'catatan_guru_screen.dart'; // Halaman baru untuk catatan guru
import 'kelas_screen.dart'; // Impor layar KelasScreen yang baru
import 'rekap_presensi_screen.dart';

class DashboardGuruScreen extends StatefulWidget {
  final Guru guru;
  const DashboardGuruScreen({super.key, required this.guru});

  @override
  State<DashboardGuruScreen> createState() => _DashboardGuruScreenState();
}

class _DashboardGuruScreenState extends State<DashboardGuruScreen> {
  final ApiService _apiService = ApiService();
  KehadiranGuru? _lastKehadiran;
  Kelas? _guruKelas;
  bool _isLoadingKelas = true;

  // Simpan pesan error saat cek kelas gagal
  String? _kelasErrorMessage;

  // --- New: preview catatan (marquee) ---
  String _lastNotePreview = '';
  final ScrollController _catatanPreviewController = ScrollController();
  Timer? _marqueeTimer;
  bool _marqueeAnimating = false;
  final Duration _marqueeDelay = const Duration(milliseconds: 800);
  final Duration _marqueeScrollDuration = const Duration(seconds: 6);
  // --- end new ---

  // --- New: preview riwayat kehadiran ---
  List<KehadiranGuru> _recentKehadiran = [];
  String _riwayatPreview = '';
  // --- end new ---

  @override
  void initState() {
    super.initState();
    _fetchInitialLastKehadiran();
    _checkGuruClass();
    _fetchLatestCatatanPreview(); // load preview on init
    _fetchRecentRiwayatKehadiran(); // load riwayat preview
  }

  /// Mengambil data kehadiran guru terakhir dari API.
  Future<void> _fetchInitialLastKehadiran() async {
    try {
      final latestKehadiranList = await _apiService.getRiwayatKehadiranGuru(
        widget.guru.nipy,
        limit: 1, // Ambil hanya 1 data terakhir
      );
      if (latestKehadiranList.isNotEmpty) {
        setState(() {
          _lastKehadiran = latestKehadiranList.first;
        });
      }
    } catch (e) {
      print('Error fetching initial last kehadiran: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memuat kehadiran terakhir: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Metode baru untuk memeriksa apakah guru memiliki kelas.
  Future<void> _checkGuruClass() async {
    try {
      final kelasData = await _apiService.getKelasByNipy(widget.guru.nipy);
      setState(() {
        _guruKelas = kelasData;
        _isLoadingKelas = false;
        _kelasErrorMessage = null;
      });
    } catch (e) {
      print('Error checking guru class: $e');
      // Set pesan yang lebih ramah sesuai permintaan
      _kelasErrorMessage = 'Anda bukan Wali Kelas';
      if (mounted) {
        final snack = SnackBar(
          content: Text('Anda bukan Wali Kelas'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Detil',
            textColor: Colors.white,
            onPressed: () => _showKelasErrorDialog(),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snack);
      }
      setState(() {
        _isLoadingKelas = false;
      });
    }
  }

  // Tampilkan dialog detil error dan opsi retry
  void _showKelasErrorDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detil Error Cek Kelas'),
        content: Text(_kelasErrorMessage ?? 'Tidak ada detil error.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isLoadingKelas = true;
              });
              _checkGuruClass();
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  /// Metode untuk logout dan membersihkan status login.
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthManager.clearLoginStatus();
      await _apiService.logout();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  /// Memformat string tanggal dan waktu menjadi format yang lebih mudah dibaca.
  String _formatDateTime(String dateTimeString) {
    try {
      DateTime dt = DateTime.parse(dateTimeString);
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error parsing date time: $e for string: $dateTimeString');
      return 'Invalid Date/Time';
    }
  }

  String _formatDate(String dateTimeString) {
    try {
      DateTime dt = DateTime.parse(dateTimeString);
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error parsing date: $e for string: $dateTimeString');
      return 'Invalid Date';
    }
  }

  // Fetch latest catatan for guru and start marquee if needed
  Future<void> _fetchLatestCatatanPreview() async {
    try {
      final list = await _apiService.getCatatanGuruList(widget.guru.nipy, '');
      print('DEBUG getCatatanGuruList result: ${list.length}');
      for (var item in list) {
        print('DEBUG item: tanggal=${item.tanggalCatatan}, text=${item.catatanText}');
      }
      if (list.isNotEmpty) {
        // Sort by tanggal_catatan descending, ambil yang terbaru
        list.sort((a, b) {
          final ta = DateTime.tryParse(a.tanggalCatatan ?? '') ?? DateTime(2000);
          final tb = DateTime.tryParse(b.tanggalCatatan ?? '') ?? DateTime(2000);
          return tb.compareTo(ta);
        });
        final latest = list.first.catatanText ?? '';
        if (mounted) {
          setState(() {
            _lastNotePreview = latest.trim();
          });
          // Pastikan animasi dipanggil setelah build selesai
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startMarquee();
          });
        }
      } else {
        print('DEBUG: Tidak ada catatan guru ditemukan.');
      }
    } catch (e) {
      print('Error fetching latest catatan preview: $e');
    }
  }

  void _startMarquee() {
    _marqueeTimer?.cancel();
    _marqueeAnimating = false;
    // Pastikan controller hanya di satu widget scroll
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final maxScroll = _catatanPreviewController.position.hasContentDimensions
          ? _catatanPreviewController.position.maxScrollExtent
          : 0.0;
      print('DEBUG marquee: preview="${_lastNotePreview}", maxScroll=$maxScroll');
      if (_lastNotePreview.isEmpty || maxScroll <= 0) return;
      // loop animation: animate to end, then jump to start after a pause
      _marqueeTimer = Timer.periodic(_marqueeScrollDuration + _marqueeDelay, (_) async {
        if (!mounted) return;
        try {
          await _catatanPreviewController.animateTo(
            _catatanPreviewController.position.maxScrollExtent,
            duration: _marqueeScrollDuration,
            curve: Curves.linear,
          );
          // small pause
          await Future.delayed(_marqueeDelay);
          if (!mounted) return;
          _catatanPreviewController.jumpTo(0);
        } catch (e) {
          print('DEBUG marquee error: $e');
        }
      });
      _marqueeAnimating = true;
    });
  }

  /// Mengambil beberapa riwayat kehadiran terakhir untuk preview
  Future<void> _fetchRecentRiwayatKehadiran() async {
    try {
      final riwayatList = await _apiService.getRiwayatKehadiranGuru(
        widget.guru.nipy,
        limit: 3, // Ambil 3 data terakhir untuk preview
      );
      if (mounted && riwayatList.isNotEmpty) {
        setState(() {
          _recentKehadiran = riwayatList;
          // Buat preview text dari 3 kehadiran terakhir
          _riwayatPreview = riwayatList.map((kehadiran) {
            final date = _formatDate(kehadiran.waktuTap);
            return '$date: ${kehadiran.status}';
          }).join(' • ');
        });
      }
    } catch (e) {
      print('Error fetching recent riwayat kehadiran: $e');
    }
  }

  @override
  void dispose() {
    _marqueeTimer?.cancel();
    _catatanPreviewController.dispose();
    super.dispose();
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
        child: RefreshIndicator(
          onRefresh: () async {
            await _fetchInitialLastKehadiran();
            await _checkGuruClass();
            await _fetchLatestCatatanPreview();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 16.0),
                  title: Text(
                    'Dashboard Guru/Tendik',
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
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/logo.png',
                            height: 80,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Selamat Datang, ${widget.guru.nama.split(' ')[0]}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${widget.guru.nipy}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: _logout,
                    tooltip: 'Logout',
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(12.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Informasi Guru',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const Divider(height: 20, thickness: 1),
                              // Menampilkan informasi guru
                              _buildInfoRow(Icons.badge, 'NIPY', widget.guru.nipy),
                              _buildInfoRow(Icons.person, 'Nama', widget.guru.nama),
                              // Baris ini diperbaiki dengan operator ??
                              _buildInfoRow(Icons.work, 'Ket ', widget.guru.ket ?? 'Tidak ada keterangan'),
                              _buildInfoRow(Icons.email, 'Email', widget.guru.email ?? 'tak ada'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Menampilkan status kehadiran terakhir
                      if (_lastKehadiran != null)
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          color: _lastKehadiran!.status == 'MASUK'
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status Kehadiran Terakhir',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: _lastKehadiran!.status == 'MASUK' ? Colors.green[700] : Colors.red[700],
                                  ),
                                ),
                                const Divider(height: 20, thickness: 1),
                                Row(
                                  children: [
                                    Icon(
                                      _lastKehadiran!.status == 'MASUK' ? Icons.login : Icons.logout,
                                      color: _lastKehadiran!.status == 'MASUK' ? Colors.green : Colors.red,
                                      size: 30,
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Status: ${_lastKehadiran!.status}',
                                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                                          ),
                                          Text(
                                            'Waktu: ${_formatDateTime(_lastKehadiran!.waktuTap)}',
                                            style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 16),
                                            softWrap: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          color: Colors.blue.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline, size: 40, color: Colors.blueAccent),
                                const SizedBox(height: 10),
                                Text(
                                  'Tidak ada data kehadiran terakhir.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.blueGrey[700],
                                  ),
                                ),
                                TextButton(
                                  onPressed: _fetchInitialLastKehadiran,
                                  child: Text(
                                    'Coba Muat Ulang',
                                    style: GoogleFonts.poppins(color: Colors.blueAccent),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      // --- New: Preview Catatan Terakhir (marquee) ---
                      // if (_lastNotePreview.isNotEmpty)
                      //   Card(
                      //     elevation: 4,
                      //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      //     child: Padding(
                      //       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      //       child: Column(
                      //         crossAxisAlignment: CrossAxisAlignment.start,
                      //         children: [
                      //           Text(
                      //             'Preview Catatan Terakhir',
                      //             style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                      //           ),
                      //           const SizedBox(height: 8),
                      //           SizedBox(
                      //             height: 36,
                      //             child: Row(
                      //               children: [
                      //                 const Icon(Icons.sticky_note_2, color: Colors.blueAccent),
                      //                 const SizedBox(width: 8),
                      //                 Expanded(
                      //                   child: ClipRect(
                      //                     child: SingleChildScrollView(
                      //                       controller: _catatanPreviewController,
                      //                       scrollDirection: Axis.horizontal,
                      //                       physics: const NeverScrollableScrollPhysics(),
                      //                       child: Text(
                      //                         _lastNotePreview,
                      //                         style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                      //                       ),
                      //                     ),
                      //                   ),
                      //                 ),
                      //               ],
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ),
                      // --- end new ---
                      const SizedBox(height: 20),

                      // Grid menu untuk guru
                      GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        children: [
                          _buildDashboardCard(
                            context,
                            title: 'Lihat Jadwal',
                            icon: Icons.calendar_today,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const JadwalScreen()),
                              );
                            },
                          ),
                          _buildDashboardCard(
                            context,
                            title: 'Riwayat Kehadiran',
                            icon: Icons.history,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFA726), Color(0xFFFFCC80)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RiwayatKehadiranGuruScreen(
                                    nipy: widget.guru.nipy,
                                  ),
                                ),
                              );
                            },
                            child: _riwayatPreview.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      _riwayatPreview,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                : null,
                          ),
                          _buildDashboardCard(
                            context,
                            title: 'Catatan Guru',
                            icon: Icons.sticky_note_2,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2196F3), Color(0xFF90CAF9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CatatanGuruScreen(nipy: widget.guru.nipy),
                                ),
                              );
                            },
                            // Tambahkan child untuk preview running text
                            child: (_lastNotePreview.isNotEmpty)
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: SizedBox(
                                      height: 24,
                                      child: Row(
                                        children: [
                                          const Icon(Icons.chevron_right, color: Colors.white70, size: 18),
                                          Expanded(
                                            child: ClipRect(
                                              child: SingleChildScrollView(
                                                controller: _catatanPreviewController,
                                                scrollDirection: Axis.horizontal,
                                                physics: const NeverScrollableScrollPhysics(),
                                                child: Text(
                                                  _lastNotePreview,
                                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          // Menu "Kelas" dengan logika kondisional
                          if (_isLoadingKelas)
                            _buildLoadingCard()
                          else
                            _buildDashboardCard(
                              context,
                              title: 'Kelas',
                              icon: Icons.class_outlined,
                              gradient: _guruKelas != null
                                  ? const LinearGradient(
                                    colors: [Color(0xFF9CCC65), Color(0xFFAED581)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                  : const LinearGradient(
                                    colors: [Color(0xFFB0BEC5), Color(0xFFCFD8DC)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                              onTap: _guruKelas != null
                                  ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => KelasScreen(namaKelas: _guruKelas!.namaKelas),
                                      ),
                                    );
                                  }
                                  : () {
                                    // Beri tahu pengguna jika guru tidak memiliki kelas.
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Anda bukan Wali Kelas',
                                          style: GoogleFonts.poppins(color: Colors.white),
                                        ),
                                        backgroundColor: Colors.red,
                                        action: _kelasErrorMessage != null ? SnackBarAction(
                                          label: 'Detil',
                                          textColor: Colors.white,
                                          onPressed: _showKelasErrorDialog,
                                        ) : null,
                                      ),
                                    );
                                  },
                            ),
                          // Tambahkan menu Rekap Presensi jika guru adalah wali kelas
                          if (_guruKelas != null)
                            _buildDashboardCard(
                              context,
                              title: 'Rekap Presensi',
                              icon: Icons.bar_chart,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF42A5F5), Color(0xFF64B5F6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              onTap: () {
                                // Ganti dengan navigasi ke halaman rekap presensi yang Anda miliki
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RekapPresensiScreen(
                                      namaKelas: _guruKelas!.namaKelas,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: VersionDisplay(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget pembantu untuk menampilkan baris informasi.
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.blueGrey[600]),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget pembantu untuk membuat kartu menu dashboard.
  Widget _buildDashboardCard(BuildContext context, {
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback? onTap,
    Widget? child, // <-- tambahkan child opsional
  }) {
    Color iconColor = onTap != null ? Colors.white : Colors.white70;
    Color textColor = onTap != null ? Colors.white : Colors.white70;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 60, color: iconColor),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (child != null) child, // <-- tampilkan preview jika ada
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget baru untuk menampilkan status loading kelas
  Widget _buildLoadingCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB0BEC5), Color(0xFFCFD8DC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                'Memuat Kelas...',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget untuk menampilkan versi aplikasi
class VersionDisplay extends StatelessWidget {
  const VersionDisplay({super.key});

  Future<String> _getVersionInfo() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return 'Versi: ${packageInfo.version} (${packageInfo.buildNumber})';
    } catch (e) {
      print('Error getting version info: $e');
      return 'Versi tidak tersedia';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getVersionInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Gagal memuat versi'));
        }
        return Center(
          child: Text(
            snapshot.data ?? 'Versi tidak tersedia',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        );
      },
    );
  }
}
