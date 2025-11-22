
import 'package:flutter/material.dart';
// <-- Tambahkan ini
// <-- Tambahkan ini
import 'package:intl/date_symbol_data_local.dart'; // Impor untuk memformat tanggal
import 'screens/splash_wrapper_screen.dart'; // Import SplashWrapperScreen
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart'; // Pastikan file ini ada setelah menjalankan 'flutterfire configure'
import 'services/local_notification_service.dart'; // <-- Impor service notifikasi

// Global navigator key to allow navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Handler untuk pesan background (harus di top-level function, tidak di dalam kelas)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase only if not already initialized, and use options
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  // Inisialisasi service notifikasi lokal untuk background
  await LocalNotificationService.init();
  print("Handling a background message: ${message.messageId}");

  // Tampilkan notifikasi lokal dari data push notification
  final notification = message.notification;
  final data = message.data;
  final title = notification?.title ?? data['title'] ?? "Pesan";
  final body = notification?.body ?? data['body'] ?? "Anda menerima pesan baru.";
  String extra = "";
  if (data['nama'] != null && data['nama']!.isNotEmpty) {
    extra = "\nNama: ${data['nama']}";
  }
  await LocalNotificationService.init();
  LocalNotificationService.showNotification(
    title: title,
    body: "$body$extra",
  );
}

void main() async {
  // Pastikan binding siap sebelum kode async lainnya
  WidgetsFlutterBinding.ensureInitialized();

  // Tambahkan global error handler untuk FirebaseException
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception is FirebaseException &&
        (details.exception as FirebaseException).code == 'apns-token-not-set') {
      print('Ignored FirebaseException: apns-token-not-set');
      return;
    }
    FlutterError.dumpErrorToConsole(details);
  };

  try {
    // Inisialisasi service notifikasi lokal
    await LocalNotificationService.init();
    // Minta izin notifikasi (untuk Android 13+)
    await LocalNotificationService.requestPermission();

    // Inisialisasi tanggal dan Firebase
    await initializeDateFormatting('id_ID', null);
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Daftarkan background handler setelah inisialisasi
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Dapatkan initial message sebelum setup listener lainnya
    final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    final initialData = initialMessage?.data;

    // Jalankan aplikasi dengan data awal jika ada
    runApp(MyApp(initialData: initialData));

    // Setup listener dan izin setelah runApp agar context siap jika diperlukan
    // (Meskipun di sini kita menggunakan navigatorKey, ini adalah praktik yang baik)
    try {
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('User granted permission: ${settings.authorizationStatus}');
    } catch (e) {
      print('Error requesting notification permission: $e');
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final data = message.data;
      final screen = data['screen'];
      if (screen == 'attendance') {
        navigatorKey.currentState?.pushNamed('/attendance', arguments: data);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.messageId}');
      final data = message.data;
      final notification = message.notification;
      final title = notification?.title ?? data['title'] ?? "Pesan";
      final body = notification?.body ?? data['body'] ?? "Anda menerima pesan baru.";
      String extra = "";
      if (data['nama'] != null && data['nama']!.isNotEmpty) {
        extra = "\nNama: ${data['nama']}";
      }
      LocalNotificationService.showNotification(
        title: title,
        body: "$body$extra",
      );
    });

    String? token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');
  } on FirebaseException catch (e) {
    if (e.code == 'apns-token-not-set') {
      print('Ignored FirebaseException in main: apns-token-not-set');
    } else {
      print('FirebaseException in main: $e');
    }
  } catch (e, stack) {
    print('Exception in main: $e\n$stack');
  }
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic>? initialData;
  const MyApp({super.key, this.initialData});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIP Siswa App',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      routes: {
        '/': (context) => const SplashWrapperScreen(),
        '/attendance': (context) => const AttendanceScreen(),
      },
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
      initialRoute: (initialData?['screen'] == 'attendance') ? '/attendance' : '/',
    );
  }
}

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    Map<String, dynamic> data = {};
    if (args is Map<String, dynamic>) {
      data = args;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Attendance screen opened via notification.\nData: $data',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// Tidak ada perubahan di file ini terkait error ScrollController.
// Error tersebut terjadi karena satu ScrollController digunakan di lebih dari satu widget scroll (biasanya di dashboard_guru_screen.dart).
// Solusi: Pastikan setiap ScrollController hanya digunakan di satu widget scroll dan dispose dengan benar.