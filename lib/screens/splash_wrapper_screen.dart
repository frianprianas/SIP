import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sip_siswa/utils/auth_manager.dart';
import 'login_screen.dart';
import 'dashboard_siswa_screen.dart';
import 'dashboard_guru_screen.dart'; // Tambahkan import dashboard guru
import '../services/api_service.dart';
// Import model guru jika perlu

class SplashWrapperScreen extends StatefulWidget {
  const SplashWrapperScreen({super.key});

  @override
  State<SplashWrapperScreen> createState() => _SplashWrapperScreenState();
}

class _SplashWrapperScreenState extends State<SplashWrapperScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    final bool loggedIn = await AuthManager.isLoggedIn();
    if (loggedIn) {
      final String? userType = await AuthManager.getLoggedInUserType();
      if (userType == 'siswa') {
        final String? nis = await AuthManager.getUserNis();
        print('DEBUG NIS: $nis'); // Tambahkan debug print
        if (nis != null && nis.isNotEmpty) {
          try {
            final siswa = await ApiService().getSiswaByNis(nis);
            print('DEBUG siswa: $siswa'); // Tambahkan debug print
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => DashboardSiswaScreen(siswa: siswa)),
              );
            }
          } catch (e) {
            print('DEBUG error getSiswaByNis: $e'); // Tambahkan debug print
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gagal memuat data siswa. Silakan login ulang.')),
              );
            }
          }
        } else {
          print('DEBUG: NIS siswa tidak ditemukan di SharedPreferences'); // Tambahkan debug print
          await AuthManager.clearLoginStatus();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        }
      } else if (userType == 'guru') {
        final String? nipy = await AuthManager.getUserNipy();
        print('DEBUG NIPY: $nipy'); // Debug print
        if (nipy != null && nipy.isNotEmpty) {
          try {
            final guru = await ApiService().getGuruByNipy(nipy);
            print('DEBUG guru: $guru'); // Debug print
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => DashboardGuruScreen(guru: guru)),
              );
            }
          } catch (e) {
            print('Error loading guru: $e');
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gagal memuat Data Silakan login ulang.')),
              );
            }
          }
        } else {
          print('DEBUG: NIPY guru tidak ditemukan di SharedPreferences'); // Debug print
          await AuthManager.clearLoginStatus();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        }
      } else {
        print('DEBUG: userType tidak valid'); // Debug print
        await AuthManager.clearLoginStatus();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } else {
      print('DEBUG: Belum login'); // Debug print
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                height: 120,
              ),
              const SizedBox(height: 20),
              Text(
                'Memuat...',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
