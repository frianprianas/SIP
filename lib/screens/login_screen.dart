import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/siswa.dart';
import '../models/guru.dart';
import '../utils/auth_manager.dart';
import '../utils/constants.dart'; // <-- Tambahkan ini
import 'dashboard_siswa_screen.dart';
import 'dashboard_guru_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  final _audioPlayer = AudioPlayer();

  // State untuk menyimpan tipe pengguna yang dipilih
  String _selectedUserType = 'siswa';

  // --- FUNGSI BARU UNTUK MENYIMPAN TOKEN ---
  Future<void> _saveTokenToServer(String token, String userId, String userType) async {
    // Menggunakan baseUrl dari AppConstants
    final url = '${AppConstants.baseUrl}/update_token.php'; 

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'user_id': userId,
          'user_type': userType,
          'fcm_token': token,
        },
      );

      if (response.statusCode == 200) {
        print('FCM Token berhasil disimpan ke server untuk user: $userId');
      } else {
        print('Gagal menyimpan FCM Token: ${response.body}');
      }
    } catch (e) {
      print('Error saat mengirim token ke server: $e');
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      dynamic result;
      // Logika login dinamis berdasarkan _selectedUserType
      if (_selectedUserType == 'siswa') {
        result = await _apiService.loginSiswa(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        result = await _apiService.loginGuru(
          _emailController.text,
          _passwordController.text,
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // Mainkan suara sukses
        try {
          await _audioPlayer.play(AssetSource('sounds/success.mp3'));
          // Hapus jeda untuk mempercepat
          // await Future.delayed(const Duration(seconds: 4)); 
        } catch (e) {
          print("Error playing audio: $e");
        }

        // --- LOGIKA SIMPAN TOKEN SETELAH LOGIN ---
        String? fcmToken;
        try {
          fcmToken = await FirebaseMessaging.instance.getToken();
        } on FirebaseException catch (e) {
          if (e.code == 'apns-token-not-set') {
            print('FCM Token belum tersedia (apns-token-not-set), login tetap dilanjutkan.');
            fcmToken = null;
          } else {
            print('FirebaseException saat ambil FCM Token: $e');
            fcmToken = null;
          }
        } catch (e) {
          print('Error saat ambil FCM Token: $e');
          fcmToken = null;
        }
        
        if (fcmToken != null) {
          String userId;
          if (_selectedUserType == 'siswa') {
            userId = (result['data'] as Siswa).nis;
          } else {
            userId = (result['data'] as Guru).nipy;
          }
          await _saveTokenToServer(fcmToken, userId, _selectedUserType);
        }
        // --- AKHIR LOGIKA SIMPAN TOKEN ---

        // Navigasi ke dashboard yang sesuai berdasarkan tipe pengguna
        if (mounted) {
          if (_selectedUserType == 'siswa') {
            // Jika login sebagai siswa, navigasi ke DashboardSiswaScreen
            final siswa = result['data'] as Siswa;
            print('DEBUG Siswa NIS: ${siswa.nis}'); // Tambahkan debug print di sini
            await AuthManager.saveSiswaLoginStatus(siswa);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => DashboardSiswaScreen(siswa: siswa),
              ),
            );
          } else {
            final guru = result['data'] as Guru;
            // MEMPERBAIKI: Menggunakan metode saveGuruLoginStatus yang benar
            await AuthManager.saveGuruLoginStatus(guru);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => DashboardGuruScreen(guru: guru),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _audioPlayer.dispose();
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 120,
                  ),
                  const SizedBox(height: 30),
                  Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedUserType == 'siswa'
                                ? 'Login Siswa'
                                : 'Login Guru/Tendik',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(height: 25),
                          DropdownButtonFormField<String>(
                            value: _selectedUserType,
                            decoration: InputDecoration(
                              labelText: 'Masuk Sebagai',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: const Icon(Icons.person, color: Colors.blueAccent),
                              filled: true,
                              fillColor: Colors.blue.shade50,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'siswa',
                                child: Text('Siswa'),
                              ),
                              DropdownMenuItem(
                                value: 'guru',
                                child: Text('Guru/Tendik'),
                              ),
                            ],
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedUserType = newValue;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Masukkan email Anda',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: const Icon(Icons.email, color: Colors.blueAccent),
                              filled: true,
                              fillColor: Colors.blue.shade50,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email tidak boleh kosong';
                              }
                              if (!value.contains('@') || !value.contains('.')) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Masukkan password Anda',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              prefixIcon: const Icon(Icons.lock, color: Colors.blueAccent),
                              filled: true,
                              fillColor: Colors.blue.shade50,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password tidak boleh kosong';
                              }
                              if (value.length < 6) {
                                return 'Password minimal 6 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                          _isLoading
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                                )
                              : Container(
                                  width: double.infinity,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4CAF50),
                                        Color(0xFF8BC34A),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.shade200.withOpacity(0.5),
                                        spreadRadius: 2,
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Text(
                                      'LOGIN',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
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
