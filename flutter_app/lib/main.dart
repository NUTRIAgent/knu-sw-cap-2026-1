import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'services/local_notification_service.dart';
import 'theme.dart';
// import 'screens/dashboard_screen.dart';
// import 'screens/main_screen.dart';
import 'screens/login_screen.dart';

const _firebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyC-ThMJGj1K3Q7XgHfI3YguHZ1fF-DoReg',
  appId: '1:78580103995:ios:5f707eb913f34eaaf0151e',
  messagingSenderId: '78580103995',
  projectId: 'nutria-b5a30',
  iosBundleId: 'com.nutria.FA',
  storageBucket: 'nutria-b5a30.firebasestorage.app',
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: _firebaseOptions);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: _firebaseOptions);
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
      home: const LoginScreen(),
      // home: const MainScreen(),
      // home: const LoginScreen(),
    );
  }
}