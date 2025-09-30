import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Callback untuk iOS versi lama
void onDidReceiveLocalNotification(
    int id, String? title, String? body, String? payload) {
  print('onDidReceiveLocalNotification: $title');
}

// Callback saat notifikasi diklik
void onNotificationTap(NotificationResponse notificationResponse) {
  print('Notification Tapped. Payload: ${notificationResponse.payload}');
}

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: onNotificationTap,
    );
  }

  static Future<void> requestPermission() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'presensi_channel',
      'Notifikasi Presensi',
      channelDescription: 'Channel untuk notifikasi status presensi.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notif'),
      enableVibration: true,
      // Hapus vibrationPattern jika suara custom tidak keluar!
      // vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      icon: '@mipmap/ic_launcher',
    );
    final details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 2147483647, // ID notifikasi unik, dijamin 32-bit
      title,
      body,
      details,
      payload: payload,
    );
  }
}