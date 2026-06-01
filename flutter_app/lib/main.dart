import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
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
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  runApp(const NutriAgentApp());
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