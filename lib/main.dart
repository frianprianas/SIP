import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart'; // Tambahkan import ini
import 'screens/login_screen.dart';
import 'screens/dashboard_siswa_screen.dart';
import 'screens/splash_wrapper_screen.dart'; // Import SplashWrapperScreen
import 'models/siswa.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Handler untuk pesan background (harus di top-level function, tidak di dalam kelas)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pastikan Firebase sudah diinisialisasi untuk background
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIP Siswa App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Tema utama aplikasi
        primarySwatch: Colors.blue, // Warna primer dasar
        primaryColor: const Color(0xFF00BCD4), // Contoh warna teal/cyan (hex #00BCD4)
        hintColor: const Color(0xFF4DD0E1), // Warna aksen
        scaffoldBackgroundColor: Colors.grey[50], // Warna latar belakang keseluruhan
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF00BCD4), // Warna AppBar
          foregroundColor: Colors.white, // Warna teks dan ikon di AppBar
          elevation: 0, // Tanpa bayangan di bawah AppBar
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00BCD4), // Warna button utama
            foregroundColor: Colors.white, // Warna teks button
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Radius button
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Radius card
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // Radius input field
            borderSide: BorderSide.none, // Hapus border standar
          ),
          filled: true,
          fillColor: Colors.grey[200], // Warna background input field
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          hintStyle: TextStyle(color: Colors.grey[600]),
          labelStyle: TextStyle(color: Colors.grey[800]),
        ),
        // Anda bisa menambahkan pengaturan tema lainnya di sini
      ),
     home: const SplashWrapperScreen(), // Ganti dengan SplashWrapperScreen
    );
  }
}