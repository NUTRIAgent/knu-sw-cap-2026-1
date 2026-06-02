import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'services/local_notification_service.dart';
import 'theme.dart';
// import 'screens/dashboard_screen.dart';
// import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await LocalNotificationService.init();
  // 알림 권한 요청 및 토큰 출력은 앱 시작을 막지 않도록 비동기로 처리
  _initFcm();
  runApp(const NutriAgentApp());
}

Future<void> _initFcm() async {
  try {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    // 앱이 포그라운드일 때도 알림 배너 표시
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) debugPrint('🔔 FCM TOKEN: $token');
  } catch (e) {
    debugPrint('FCM 초기화 스킵 (시뮬레이터 또는 권한 없음): $e');
  }
}

class NutriAgentApp extends StatelessWidget {
  const NutriAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NUTRI Agent',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // 💡 앱 시작 시 자동 로그인 여부를 판단하는 스플래시 화면으로 진입
      home: const SplashScreen(),
      // home: const MainScreen(),
      // home: const LoginScreen(),
    );
  }
}