import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sip_siswa/utils/auth_manager.dart'; // Import AuthManager yang terpusat
import 'package:package_info_plus/package_info_plus.dart'; // Import yang ditambahkan

import '../models/siswa.dart';
import '../models/kehadiran.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'jadwal_screen.dart';
import 'riwayat_presensi_screen.dart';
import 'catatan_screen.dart'; //hide ApiService, Kehadiran; // Tambahkan import ini jika Anda sudah membuat CatatanScreen

class DashboardSiswaScreen extends StatefulWidget {
  final Siswa siswa;
  const DashboardSiswaScreen({super.key, required this.siswa});

  @override
  State<DashboardSiswaScreen> createState() => _DashboardSiswaScreenState();
}

class _DashboardSiswaScreenState extends State<DashboardSiswaScreen> {
  final ApiService _apiService = ApiService();
  Kehadiran? _lastKehadiran;

  // Preview catatan siswa (marquee)
  String _lastNotePreview = '';
  final ScrollController _catatanPreviewController = ScrollController();
  Timer? _marqueeTimer;
  final Duration _marqueeDelay = const Duration(milliseconds: 800);
  final Duration _marqueeScrollDuration = const Duration(seconds: 6);

  @override
  void initState() {
    super.initState();
    // Tidak perlu lagi memanggil _saveNisOnLogin() karena sudah dilakukan di LoginScreen
    _fetchInitialLastPresensi();
    _fetchLatestCatatanPreview();
  }

  Future<void> _fetchInitialLastPresensi() async {
    try {
      final latestPresensiList = await _apiService.getRiwayatPresensi(
        widget.siswa.nis,
        limit: 1, // Ambil hanya 1 data terakhir
      );
      if (latestPresensiList.isNotEmpty) {
        setState(() {
          _lastKehadiran = latestPresensiList.first;
        });
      }
    } catch (e) {
      print('Error fetching initial last presensi: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memuat presensi terakhir: $e',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchLatestCatatanPreview() async {
    try {
      final list = await _apiService.getCatatanList(nis: widget.siswa.nis);
      if (list.isNotEmpty) {
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startMarquee();
          });
        }
      }
    } catch (e) {
      print('Error fetching latest catatan preview siswa: $e');
    }
  }

  void _startMarquee() {
    _marqueeTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final maxScroll = _catatanPreviewController.position.hasContentDimensions
          ? _catatanPreviewController.position.maxScrollExtent
          : 0.0;
      if (_lastNotePreview.isEmpty || maxScroll <= 0) return;
      _marqueeTimer = Timer.periodic(_marqueeScrollDuration + _marqueeDelay, (_) async {
        if (!mounted) return;
        try {
          await _catatanPreviewController.animateTo(
            _catatanPreviewController.position.maxScrollExtent,
            duration: _marqueeScrollDuration,
            curve: Curves.linear,
          );
          await Future.delayed(_marqueeDelay);
          if (!mounted) return;
          _catatanPreviewController.jumpTo(0);
        } catch (e) {}
      });
    });
  }

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

  String _formatDateTime(String dateTimeString) {
    try {
      DateTime dt = DateTime.parse(dateTimeString);
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error parsing date time: $e for string: $dateTimeString');
      return 'Invalid Date/Time';
    }
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
            await _fetchInitialLastPresensi();
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
                    'Dashboard Siswa',
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
                            'Selamat Datang, ${widget.siswa.nama.split(' ')[0]}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${widget.siswa.nis}',
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
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(25.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Informasi Siswa',
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              const Divider(height: 20, thickness: 1),
                              _buildInfoRow(Icons.badge, 'NIS', widget.siswa.nis),
                              _buildInfoRow(Icons.person, 'Nama', widget.siswa.nama),
                              _buildInfoRow(Icons.class_, 'Kelas', widget.siswa.kelas),
                              _buildInfoRow(Icons.email, 'Email', widget.siswa.email),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_lastKehadiran != null)
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          color: _lastKehadiran!.status == 'MASUK'
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(25.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status Presensi Terakhir',
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
                                      _lastKehadiran!.status == 'MASUK' ? Icons.check_circle_outline : Icons.highlight_off,
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
                            padding: const EdgeInsets.all(25.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline, size: 40, color: Colors.blueAccent),
                                const SizedBox(height: 10),
                                Text(
                                  'Tidak ada data presensi terakhir.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.blueGrey[700],
                                  ),
                                ),
                                TextButton(
                                  onPressed: _fetchInitialLastPresensi,
                                  child: Text(
                                    'Coba Muat Ulang',
                                    style: GoogleFonts.poppins(color: Colors.blueAccent),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 30),

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
                            title: 'Riwayat Presensi',
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
                                    builder: (context) => RiwayatPresensiScreen(
                                          nis: widget.siswa.nis,
                                        )),
                              );
                            },
                          ),
                          // --- Bagian yang diubah: "Profil Saya" menjadi "Catatan" ---
                          _buildDashboardCard(
                            context,
                            title: 'Catatan', // Perubahan nama
                            icon: Icons.sticky_note_2, // Perubahan ikon
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2196F3), Color(0xFF90CAF9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () {
                              // Tambahkan navigasi ke CatatanScreen di sini
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CatatanScreen(nis: widget.siswa.nis)),
                              );
                            },
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
                          // -----------------------------------------------------------
                          _buildDashboardCard(
                            context,
                            title: 'Informasi',
                            icon: Icons.info_outline,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFB0BEC5), Color(0xFFCFD8DC)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onTap: () {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(
                                    'Fitur informasi akan datang!',
                                    style: GoogleFonts.poppins(color: Colors.white),
                                  )),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      // Widget versi aplikasi ditambahkan di sini
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

  Widget _buildDashboardCard(BuildContext context, {
    required String title,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
    Widget? child,
  }) {
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
                Icon(icon, size: 60, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (child != null) child,
              ],
            ),
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
