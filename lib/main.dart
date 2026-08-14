import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Lafla/pages/messages_page.dart';
import 'services/api_client.dart';
import 'themes/tema1.dart';
import 'pages/login.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// --- TEMA DURUMU İÇİN GLOBAL NOTIFIER ---
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Kayıtlı tema tercihini yükle
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool("isDarkMode") ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(settings);

  Future<void> setupFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;

    // Android + iOS bildirim izni
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // iOS'ta APNs token hazır olmadan getToken() çağırma
    if (Platform.isIOS) {
      String? apnsToken;

      for (int i = 0; i < 10; i++) {
        apnsToken = await messaging.getAPNSToken();

        if (apnsToken != null) {
          break;
        }

        await Future.delayed(const Duration(seconds: 1));
      }

      print("APNS TOKEN: $apnsToken");

      if (apnsToken == null) {
        print("APNS token alınamadı.");
        return;
      }
    }

    // APNs hazır olduktan sonra FCM token al
    final fcmToken = await messaging.getToken();

    print("FCM TOKEN: $fcmToken");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print("========== YENI BILDIRIM ==========");
      print("Title: ${message.notification?.title}");
      print("Body : ${message.notification?.body}");
      print("Data : ${message.data}");

      final notification = message.notification;

      // Local notification sadece Android'de gösteriliyor
      if (Platform.isAndroid && notification != null) {
        await flutterLocalNotificationsPlugin.show(
          0,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'chat_channel',
              'Chat Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  await setupFirebaseMessaging();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentMode, __) {
        return MaterialApp(
          title: 'Staj Uygulaması',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode, // Switch butonuna bağlanan dinamik mod
          home: const AuthCheckPage(),
        );
      },
    );
  }
}

class AuthCheckPage extends StatefulWidget {
  const AuthCheckPage({super.key});

  @override
  State<AuthCheckPage> createState() => _AuthCheckPageState();
}

class _AuthCheckPageState extends State<AuthCheckPage> {
  final ApiClient api = ApiClient();

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      _goToLogin();
      return;
    }
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MessagesPage()),
    );
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
